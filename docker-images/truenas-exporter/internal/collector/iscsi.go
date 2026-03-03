package collector

import (
	"context"
	"fmt"
	"log/slog"

	"github.com/GiganticMinecraft/truenas-exporter/internal/client"
	"github.com/prometheus/client_golang/prometheus"
)

type ISCSICollector struct {
	client *client.Client

	sessionsActive *prometheus.Desc
	sessionInfo    *prometheus.Desc
	targetInfo     *prometheus.Desc
	extentEnabled  *prometheus.Desc
}

func NewISCSICollector(c *client.Client) *ISCSICollector {
	return &ISCSICollector{
		client: c,
		sessionsActive: prometheus.NewDesc(
			"truenas_iscsi_sessions_active",
			"Number of active iSCSI sessions",
			nil, nil,
		),
		sessionInfo: prometheus.NewDesc(
			"truenas_iscsi_session_info",
			"Information about an active iSCSI session (always 1)",
			[]string{"initiator", "target"}, nil,
		),
		targetInfo: prometheus.NewDesc(
			"truenas_iscsi_target_info",
			"Information about an iSCSI target (always 1)",
			[]string{"id", "name"}, nil,
		),
		extentEnabled: prometheus.NewDesc(
			"truenas_iscsi_extent_enabled",
			"Whether an iSCSI extent is enabled (1 = enabled, 0 = disabled)",
			[]string{"name", "disk"}, nil,
		),
	}
}

func (c *ISCSICollector) Describe(ch chan<- *prometheus.Desc) {
	ch <- c.sessionsActive
	ch <- c.sessionInfo
	ch <- c.targetInfo
	ch <- c.extentEnabled
}

func (c *ISCSICollector) Collect(ch chan<- prometheus.Metric) {
	ctx := context.Background()

	sessions, err := c.client.GetISCSISessions(ctx)
	if err != nil {
		slog.Error("failed to get iscsi sessions", "error", err)
	} else {
		ch <- prometheus.MustNewConstMetric(c.sessionsActive, prometheus.GaugeValue, float64(len(sessions)))
		for _, s := range sessions {
			ch <- prometheus.MustNewConstMetric(c.sessionInfo, prometheus.GaugeValue, 1, s.Initiator, s.TargetAlias)
		}
	}

	targets, err := c.client.GetISCSITargets(ctx)
	if err != nil {
		slog.Error("failed to get iscsi targets", "error", err)
	} else {
		for _, t := range targets {
			ch <- prometheus.MustNewConstMetric(c.targetInfo, prometheus.GaugeValue, 1, fmt.Sprintf("%d", t.ID), t.Name)
		}
	}

	extents, err := c.client.GetISCSIExtents(ctx)
	if err != nil {
		slog.Error("failed to get iscsi extents", "error", err)
	} else {
		for _, e := range extents {
			enabled := 0.0
			if e.Enabled {
				enabled = 1.0
			}
			ch <- prometheus.MustNewConstMetric(c.extentEnabled, prometheus.GaugeValue, enabled, e.Name, e.Disk)
		}
	}
}
