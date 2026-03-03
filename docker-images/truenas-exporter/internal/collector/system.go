package collector

import (
	"context"
	"log/slog"

	"github.com/GiganticMinecraft/truenas-exporter/internal/client"
	"github.com/prometheus/client_golang/prometheus"
)

type SystemCollector struct {
	client *client.Client

	info          *prometheus.Desc
	uptimeSeconds *prometheus.Desc
}

func NewSystemCollector(c *client.Client) *SystemCollector {
	return &SystemCollector{
		client: c,
		info: prometheus.NewDesc(
			"truenas_system_info",
			"TrueNAS system information (always 1)",
			[]string{"version", "hostname"}, nil,
		),
		uptimeSeconds: prometheus.NewDesc(
			"truenas_system_uptime_seconds",
			"System uptime in seconds",
			nil, nil,
		),
	}
}

func (c *SystemCollector) Describe(ch chan<- *prometheus.Desc) {
	ch <- c.info
	ch <- c.uptimeSeconds
}

func (c *SystemCollector) Collect(ch chan<- prometheus.Metric) {
	ctx := context.Background()

	info, err := c.client.GetSystemInfo(ctx)
	if err != nil {
		slog.Error("failed to get system info", "error", err)
		return
	}

	ch <- prometheus.MustNewConstMetric(c.info, prometheus.GaugeValue, 1, info.Version, info.Hostname)
	ch <- prometheus.MustNewConstMetric(c.uptimeSeconds, prometheus.GaugeValue, info.UptimeSeconds)
}
