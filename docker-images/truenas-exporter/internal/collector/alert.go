package collector

import (
	"context"
	"log/slog"
	"strings"

	"github.com/GiganticMinecraft/truenas-exporter/internal/client"
	"github.com/prometheus/client_golang/prometheus"
)

type AlertCollector struct {
	client *client.Client

	activeTotal *prometheus.Desc
}

func NewAlertCollector(c *client.Client) *AlertCollector {
	return &AlertCollector{
		client: c,
		activeTotal: prometheus.NewDesc(
			"truenas_alerts_active_total",
			"Number of active (non-dismissed) alerts by level",
			[]string{"level"}, nil,
		),
	}
}

func (c *AlertCollector) Describe(ch chan<- *prometheus.Desc) {
	ch <- c.activeTotal
}

// knownAlertLevels are the levels TrueNAS uses for alerts.
// We always emit these so that Grafana panels don't break on zero-alert states.
var knownAlertLevels = []string{"info", "notice", "warning", "error", "critical", "alert", "emergency"}

func (c *AlertCollector) Collect(ch chan<- prometheus.Metric) {
	ctx := context.Background()

	alerts, err := c.client.GetAlerts(ctx)
	if err != nil {
		slog.Error("failed to get alerts", "error", err)
		return
	}

	counts := make(map[string]float64, len(knownAlertLevels))
	for _, level := range knownAlertLevels {
		counts[level] = 0
	}

	for _, a := range alerts {
		if !a.Dismissed {
			counts[strings.ToLower(a.Level)]++
		}
	}

	for level, count := range counts {
		ch <- prometheus.MustNewConstMetric(c.activeTotal, prometheus.GaugeValue, count, level)
	}
}
