package collector

import (
	"context"
	"log/slog"
	"strings"

	"github.com/GiganticMinecraft/truenas-exporter/internal/client"
	"github.com/prometheus/client_golang/prometheus"
)

type PoolCollector struct {
	client *client.Client

	usedBytes      *prometheus.Desc
	availableBytes *prometheus.Desc
	status         *prometheus.Desc
}

func NewPoolCollector(c *client.Client) *PoolCollector {
	return &PoolCollector{
		client: c,
		usedBytes: prometheus.NewDesc(
			"truenas_pool_used_bytes",
			"Used bytes of the ZFS pool",
			[]string{"pool"}, nil,
		),
		availableBytes: prometheus.NewDesc(
			"truenas_pool_available_bytes",
			"Available bytes of the ZFS pool",
			[]string{"pool"}, nil,
		),
		status: prometheus.NewDesc(
			"truenas_pool_status",
			"Status of the ZFS pool (1 = current status)",
			[]string{"pool", "status"}, nil,
		),
	}
}

func (c *PoolCollector) Describe(ch chan<- *prometheus.Desc) {
	ch <- c.usedBytes
	ch <- c.availableBytes
	ch <- c.status
}

func (c *PoolCollector) Collect(ch chan<- prometheus.Metric) {
	ctx := context.Background()

	pools, err := c.client.GetPools(ctx)
	if err != nil {
		slog.Error("failed to get pools", "error", err)
		return
	}

	for _, pool := range pools {
		ch <- prometheus.MustNewConstMetric(
			c.status, prometheus.GaugeValue, 1,
			pool.Name, strings.ToLower(pool.Status),
		)
	}

	datasets, err := c.client.GetDatasets(ctx)
	if err != nil {
		slog.Error("failed to get datasets for pool metrics", "error", err)
		return
	}

	for _, ds := range datasets {
		if ds.Type != "FILESYSTEM" || strings.Contains(ds.Name, "/") {
			continue
		}
		if ds.Used != nil {
			if v, ok := toFloat64(ds.Used.Parsed); ok {
				ch <- prometheus.MustNewConstMetric(c.usedBytes, prometheus.GaugeValue, v, ds.Name)
			}
		}
		if ds.Available != nil {
			if v, ok := toFloat64(ds.Available.Parsed); ok {
				ch <- prometheus.MustNewConstMetric(c.availableBytes, prometheus.GaugeValue, v, ds.Name)
			}
		}
	}
}
