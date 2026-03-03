package collector

import (
	"github.com/GiganticMinecraft/truenas-exporter/internal/client"
	"github.com/prometheus/client_golang/prometheus"
)

// RegisterAll registers all TrueNAS collectors with the given registry.
func RegisterAll(reg prometheus.Registerer, c *client.Client) {
	reg.MustRegister(
		NewPoolCollector(c),
		NewDatasetCollector(c),
		NewISCSICollector(c),
		NewDiskCollector(c),
		NewSystemCollector(c),
		NewAlertCollector(c),
	)
}
