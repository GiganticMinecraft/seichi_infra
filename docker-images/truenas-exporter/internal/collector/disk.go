package collector

import (
	"context"
	"log/slog"

	"github.com/GiganticMinecraft/truenas-exporter/internal/client"
	"github.com/prometheus/client_golang/prometheus"
)

type DiskCollector struct {
	client *client.Client

	temperatureCelsius *prometheus.Desc
	sizeBytes          *prometheus.Desc
}

func NewDiskCollector(c *client.Client) *DiskCollector {
	return &DiskCollector{
		client: c,
		temperatureCelsius: prometheus.NewDesc(
			"truenas_disk_temperature_celsius",
			"Current temperature of the disk in Celsius",
			[]string{"disk", "serial", "model"}, nil,
		),
		sizeBytes: prometheus.NewDesc(
			"truenas_disk_size_bytes",
			"Size of the disk in bytes",
			[]string{"disk", "serial", "model"}, nil,
		),
	}
}

func (c *DiskCollector) Describe(ch chan<- *prometheus.Desc) {
	ch <- c.temperatureCelsius
	ch <- c.sizeBytes
}

func (c *DiskCollector) Collect(ch chan<- prometheus.Metric) {
	ctx := context.Background()

	disks, err := c.client.GetDisks(ctx)
	if err != nil {
		slog.Error("failed to get disks", "error", err)
		return
	}

	disksByName := make(map[string]client.Disk, len(disks))
	for _, d := range disks {
		disksByName[d.Name] = d
		ch <- prometheus.MustNewConstMetric(c.sizeBytes, prometheus.GaugeValue, float64(d.Size), d.Name, d.Serial, d.Model)
	}

	// Temperature is fetched from a separate POST /disk/temperatures endpoint.
	temps, err := c.client.GetDiskTemperatures(ctx)
	if err != nil {
		slog.Error("failed to get disk temperatures", "error", err)
		return
	}

	for name, temp := range temps {
		d, ok := disksByName[name]
		if !ok {
			continue
		}
		ch <- prometheus.MustNewConstMetric(c.temperatureCelsius, prometheus.GaugeValue, temp, d.Name, d.Serial, d.Model)
	}
}
