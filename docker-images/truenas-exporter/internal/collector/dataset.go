package collector

import (
	"context"
	"log/slog"
	"strconv"
	"strings"

	"github.com/GiganticMinecraft/truenas-exporter/internal/client"
	"github.com/prometheus/client_golang/prometheus"
)

type DatasetCollector struct {
	client *client.Client

	usedBytes      *prometheus.Desc
	availableBytes *prometheus.Desc
	volsizeBytes   *prometheus.Desc
	quotaBytes     *prometheus.Desc
	compressRatio  *prometheus.Desc
}

func NewDatasetCollector(c *client.Client) *DatasetCollector {
	return &DatasetCollector{
		client: c,
		usedBytes: prometheus.NewDesc(
			"truenas_dataset_used_bytes",
			"Used bytes of the dataset or zvol",
			[]string{"dataset", "type"}, nil,
		),
		availableBytes: prometheus.NewDesc(
			"truenas_dataset_available_bytes",
			"Available bytes of the dataset or zvol",
			[]string{"dataset", "type"}, nil,
		),
		volsizeBytes: prometheus.NewDesc(
			"truenas_zvol_volsize_bytes",
			"Volume size of the zvol in bytes",
			[]string{"zvol"}, nil,
		),
		quotaBytes: prometheus.NewDesc(
			"truenas_dataset_quota_bytes",
			"Quota of the dataset in bytes (0 = no quota)",
			[]string{"dataset"}, nil,
		),
		compressRatio: prometheus.NewDesc(
			"truenas_dataset_compressratio",
			"Compression ratio of the dataset",
			[]string{"dataset"}, nil,
		),
	}
}

func (c *DatasetCollector) Describe(ch chan<- *prometheus.Desc) {
	ch <- c.usedBytes
	ch <- c.availableBytes
	ch <- c.volsizeBytes
	ch <- c.quotaBytes
	ch <- c.compressRatio
}

func (c *DatasetCollector) Collect(ch chan<- prometheus.Metric) {
	ctx := context.Background()

	datasets, err := c.client.GetDatasets(ctx)
	if err != nil {
		slog.Error("failed to get datasets", "error", err)
		return
	}

	// With extra.flat=true, the API returns each dataset exactly once at the top level.
	for _, ds := range datasets {
		dsType := strings.ToLower(ds.Type)

		if ds.Used != nil {
			if v, ok := toFloat64(ds.Used.Parsed); ok {
				ch <- prometheus.MustNewConstMetric(c.usedBytes, prometheus.GaugeValue, v, ds.Name, dsType)
			}
		}
		if ds.Available != nil {
			if v, ok := toFloat64(ds.Available.Parsed); ok {
				ch <- prometheus.MustNewConstMetric(c.availableBytes, prometheus.GaugeValue, v, ds.Name, dsType)
			}
		}
		if ds.Type == "VOLUME" && ds.VolSize != nil {
			if v, ok := toFloat64(ds.VolSize.Parsed); ok {
				ch <- prometheus.MustNewConstMetric(c.volsizeBytes, prometheus.GaugeValue, v, ds.Name)
			}
		}
		if ds.Type == "FILESYSTEM" {
			// Quota: parsed can be null (None) when no quota is set.
			// Use rawvalue which is always present as a numeric string.
			quota := 0.0
			if ds.Quota != nil && ds.Quota.RawValue != "" {
				if v, err := strconv.ParseFloat(ds.Quota.RawValue, 64); err == nil {
					quota = v
				}
			}
			ch <- prometheus.MustNewConstMetric(c.quotaBytes, prometheus.GaugeValue, quota, ds.Name)
		}
		if ds.CompressRatio != nil {
			if v, ok := toFloat64(ds.CompressRatio.Parsed); ok {
				ch <- prometheus.MustNewConstMetric(c.compressRatio, prometheus.GaugeValue, v, ds.Name)
			}
		}
	}
}
