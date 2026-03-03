package collector_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/GiganticMinecraft/truenas-exporter/internal/client"
	"github.com/GiganticMinecraft/truenas-exporter/internal/collector"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/testutil"
)

// newTestServer creates a test HTTP server that serves mock TrueNAS API responses.
func newTestServer(responses map[string]any) *httptest.Server {
	return httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Match on path + query string
		key := r.URL.Path
		if r.URL.RawQuery != "" {
			key += "?" + r.URL.RawQuery
		}
		resp, ok := responses[key]
		if !ok {
			// Fallback: try path only
			resp, ok = responses[r.URL.Path]
		}
		if !ok {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
	}))
}

func newTestClient(ts *httptest.Server) *client.Client {
	httpClient := ts.Client()

	origTransport := httpClient.Transport
	httpClient.Transport = roundTripFunc(func(req *http.Request) (*http.Response, error) {
		req.URL.Scheme = "https"
		req.URL.Host = ts.Listener.Addr().String()
		return origTransport.RoundTrip(req)
	})

	return client.NewWithHTTPClient("127.0.0.1", 443, "test-key", httpClient)
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}

func TestPoolCollector(t *testing.T) {
	ts := newTestServer(map[string]any{
		"/api/v2.0/pool": []map[string]any{
			{"id": 1, "name": "tank", "status": "ONLINE"},
		},
		"/api/v2.0/pool/dataset": []map[string]any{
			{
				"id":        "tank",
				"name":      "tank",
				"type":      "FILESYSTEM",
				"used":      map[string]any{"parsed": 1073741824.0, "value": "1G"},
				"available": map[string]any{"parsed": 9663676416.0, "value": "9G"},
				"children":  []any{},
			},
		},
	})
	defer ts.Close()

	c := newTestClient(ts)
	reg := prometheus.NewRegistry()
	reg.MustRegister(collector.NewPoolCollector(c))

	expected := `
# HELP truenas_pool_status Status of the ZFS pool (1 = current status)
# TYPE truenas_pool_status gauge
truenas_pool_status{pool="tank",status="online"} 1
# HELP truenas_pool_used_bytes Used bytes of the ZFS pool
# TYPE truenas_pool_used_bytes gauge
truenas_pool_used_bytes{pool="tank"} 1.073741824e+09
# HELP truenas_pool_available_bytes Available bytes of the ZFS pool
# TYPE truenas_pool_available_bytes gauge
truenas_pool_available_bytes{pool="tank"} 9.663676416e+09
`
	if err := testutil.GatherAndCompare(reg, strings.NewReader(expected)); err != nil {
		t.Errorf("unexpected metrics:\n%s", err)
	}
}

func TestDatasetCollector(t *testing.T) {
	ts := newTestServer(map[string]any{
		"/api/v2.0/pool/dataset": []map[string]any{
			{
				"id":            "tank",
				"name":          "tank",
				"type":          "FILESYSTEM",
				"used":          map[string]any{"parsed": 1073741824.0, "value": "1G"},
				"available":     map[string]any{"parsed": 9663676416.0, "value": "9G"},
				"quota":         map[string]any{"parsed": nil, "rawvalue": "0", "value": nil},
				"compressratio": map[string]any{"parsed": 1.5, "value": "1.50x"},
				"children":      []any{},
			},
			{
				"id":            "tank/data",
				"name":          "tank/data",
				"type":          "FILESYSTEM",
				"used":          map[string]any{"parsed": 524288000.0, "value": "500M"},
				"available":     map[string]any{"parsed": 9663676416.0, "value": "9G"},
				"quota":         map[string]any{"parsed": 1073741824.0, "rawvalue": "1073741824", "value": "1G"},
				"compressratio": map[string]any{"parsed": 1.2, "value": "1.20x"},
				"children":      []any{},
			},
		},
	})
	defer ts.Close()

	c := newTestClient(ts)
	reg := prometheus.NewRegistry()
	reg.MustRegister(collector.NewDatasetCollector(c))

	expected := `
# HELP truenas_dataset_used_bytes Used bytes of the dataset or zvol
# TYPE truenas_dataset_used_bytes gauge
truenas_dataset_used_bytes{dataset="tank",type="filesystem"} 1.073741824e+09
truenas_dataset_used_bytes{dataset="tank/data",type="filesystem"} 5.24288e+08
# HELP truenas_dataset_available_bytes Available bytes of the dataset or zvol
# TYPE truenas_dataset_available_bytes gauge
truenas_dataset_available_bytes{dataset="tank",type="filesystem"} 9.663676416e+09
truenas_dataset_available_bytes{dataset="tank/data",type="filesystem"} 9.663676416e+09
# HELP truenas_dataset_quota_bytes Quota of the dataset in bytes (0 = no quota)
# TYPE truenas_dataset_quota_bytes gauge
truenas_dataset_quota_bytes{dataset="tank"} 0
truenas_dataset_quota_bytes{dataset="tank/data"} 1.073741824e+09
# HELP truenas_dataset_compressratio Compression ratio of the dataset
# TYPE truenas_dataset_compressratio gauge
truenas_dataset_compressratio{dataset="tank"} 1.5
truenas_dataset_compressratio{dataset="tank/data"} 1.2
`
	if err := testutil.GatherAndCompare(reg, strings.NewReader(expected)); err != nil {
		t.Errorf("unexpected metrics:\n%s", err)
	}
}

func TestISCSICollector(t *testing.T) {
	ts := newTestServer(map[string]any{
		"/api/v2.0/iscsi/global/sessions": []map[string]any{
			{"initiator": "iqn.2024.client:node1", "target_alias": "target0"},
		},
		"/api/v2.0/iscsi/target": []map[string]any{
			{"id": 1, "name": "target0"},
		},
		"/api/v2.0/iscsi/extent": []map[string]any{
			{"id": 1, "name": "extent0", "disk": "zvol/tank/iscsi/disk0", "enabled": true},
		},
	})
	defer ts.Close()

	c := newTestClient(ts)
	reg := prometheus.NewRegistry()
	reg.MustRegister(collector.NewISCSICollector(c))

	expected := `
# HELP truenas_iscsi_sessions_active Number of active iSCSI sessions
# TYPE truenas_iscsi_sessions_active gauge
truenas_iscsi_sessions_active 1
# HELP truenas_iscsi_session_info Information about an active iSCSI session (always 1)
# TYPE truenas_iscsi_session_info gauge
truenas_iscsi_session_info{initiator="iqn.2024.client:node1",target="target0"} 1
# HELP truenas_iscsi_target_info Information about an iSCSI target (always 1)
# TYPE truenas_iscsi_target_info gauge
truenas_iscsi_target_info{id="1",name="target0"} 1
# HELP truenas_iscsi_extent_enabled Whether an iSCSI extent is enabled (1 = enabled, 0 = disabled)
# TYPE truenas_iscsi_extent_enabled gauge
truenas_iscsi_extent_enabled{disk="zvol/tank/iscsi/disk0",name="extent0"} 1
`
	if err := testutil.GatherAndCompare(reg, strings.NewReader(expected)); err != nil {
		t.Errorf("unexpected metrics:\n%s", err)
	}
}

func TestDiskCollector(t *testing.T) {
	ts := newTestServer(map[string]any{
		"/api/v2.0/disk": []map[string]any{
			{"name": "sda", "serial": "ABC123", "model": "WDC WD100", "size": 1000204886016},
			{"name": "sdb", "serial": "DEF456", "model": "WDC WD100", "size": 1000204886016},
		},
		"/api/v2.0/disk/temperatures": map[string]any{
			"sda": 35.0,
			"sdb": 37.0,
		},
	})
	defer ts.Close()

	c := newTestClient(ts)
	reg := prometheus.NewRegistry()
	reg.MustRegister(collector.NewDiskCollector(c))

	expected := `
# HELP truenas_disk_size_bytes Size of the disk in bytes
# TYPE truenas_disk_size_bytes gauge
truenas_disk_size_bytes{disk="sda",model="WDC WD100",serial="ABC123"} 1.000204886016e+12
truenas_disk_size_bytes{disk="sdb",model="WDC WD100",serial="DEF456"} 1.000204886016e+12
# HELP truenas_disk_temperature_celsius Current temperature of the disk in Celsius
# TYPE truenas_disk_temperature_celsius gauge
truenas_disk_temperature_celsius{disk="sda",model="WDC WD100",serial="ABC123"} 35
truenas_disk_temperature_celsius{disk="sdb",model="WDC WD100",serial="DEF456"} 37
`
	if err := testutil.GatherAndCompare(reg, strings.NewReader(expected)); err != nil {
		t.Errorf("unexpected metrics:\n%s", err)
	}
}

func TestSystemCollector(t *testing.T) {
	ts := newTestServer(map[string]any{
		"/api/v2.0/system/info": map[string]any{
			"version":        "TrueNAS-SCALE-24.10",
			"hostname":       "truenas",
			"uptime_seconds": 86400.123,
		},
	})
	defer ts.Close()

	c := newTestClient(ts)
	reg := prometheus.NewRegistry()
	reg.MustRegister(collector.NewSystemCollector(c))

	expected := `
# HELP truenas_system_info TrueNAS system information (always 1)
# TYPE truenas_system_info gauge
truenas_system_info{hostname="truenas",version="TrueNAS-SCALE-24.10"} 1
# HELP truenas_system_uptime_seconds System uptime in seconds
# TYPE truenas_system_uptime_seconds gauge
truenas_system_uptime_seconds 86400.123
`
	if err := testutil.GatherAndCompare(reg, strings.NewReader(expected)); err != nil {
		t.Errorf("unexpected metrics:\n%s", err)
	}
}

func TestAlertCollector(t *testing.T) {
	ts := newTestServer(map[string]any{
		"/api/v2.0/alert/list": []map[string]any{
			{"level": "WARNING", "dismissed": false},
			{"level": "WARNING", "dismissed": false},
			{"level": "CRITICAL", "dismissed": false},
			{"level": "INFO", "dismissed": true},
		},
	})
	defer ts.Close()

	c := newTestClient(ts)
	reg := prometheus.NewRegistry()
	reg.MustRegister(collector.NewAlertCollector(c))

	expected := `
# HELP truenas_alerts_active_total Number of active (non-dismissed) alerts by level
# TYPE truenas_alerts_active_total gauge
truenas_alerts_active_total{level="alert"} 0
truenas_alerts_active_total{level="critical"} 1
truenas_alerts_active_total{level="emergency"} 0
truenas_alerts_active_total{level="error"} 0
truenas_alerts_active_total{level="info"} 0
truenas_alerts_active_total{level="notice"} 0
truenas_alerts_active_total{level="warning"} 2
`
	if err := testutil.GatherAndCompare(reg, strings.NewReader(expected)); err != nil {
		t.Errorf("unexpected metrics:\n%s", err)
	}
}

func TestAlertCollector_NoAlerts(t *testing.T) {
	ts := newTestServer(map[string]any{
		"/api/v2.0/alert/list": []map[string]any{},
	})
	defer ts.Close()

	c := newTestClient(ts)
	reg := prometheus.NewRegistry()
	reg.MustRegister(collector.NewAlertCollector(c))

	expected := `
# HELP truenas_alerts_active_total Number of active (non-dismissed) alerts by level
# TYPE truenas_alerts_active_total gauge
truenas_alerts_active_total{level="alert"} 0
truenas_alerts_active_total{level="critical"} 0
truenas_alerts_active_total{level="emergency"} 0
truenas_alerts_active_total{level="error"} 0
truenas_alerts_active_total{level="info"} 0
truenas_alerts_active_total{level="notice"} 0
truenas_alerts_active_total{level="warning"} 0
`
	if err := testutil.GatherAndCompare(reg, strings.NewReader(expected)); err != nil {
		t.Errorf("unexpected metrics:\n%s", err)
	}
}
