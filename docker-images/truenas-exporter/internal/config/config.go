package config

import (
	"fmt"
	"os"
	"strconv"
)

type Config struct {
	TrueNASHost          string
	TrueNASPort          int
	TrueNASAPIKey        string
	TrueNASTLSSkipVerify bool
	ListenAddr           string
}

func Load() (*Config, error) {
	apiKey := os.Getenv("TRUENAS_API_KEY")
	if apiKey == "" {
		return nil, fmt.Errorf("TRUENAS_API_KEY is required")
	}

	host := os.Getenv("TRUENAS_HOST")
	if host == "" {
		host = "192.168.16.234"
	}

	portStr := os.Getenv("TRUENAS_PORT")
	if portStr == "" {
		portStr = "443"
	}
	port, err := strconv.Atoi(portStr)
	if err != nil {
		return nil, fmt.Errorf("invalid TRUENAS_PORT: %w", err)
	}

	tlsSkipVerify := false
	if v := os.Getenv("TRUENAS_TLS_SKIP_VERIFY"); v != "" {
		tlsSkipVerify, err = strconv.ParseBool(v)
		if err != nil {
			return nil, fmt.Errorf("invalid TRUENAS_TLS_SKIP_VERIFY: %w", err)
		}
	}

	listenAddr := os.Getenv("LISTEN_ADDR")
	if listenAddr == "" {
		listenAddr = ":9814"
	}

	return &Config{
		TrueNASHost:          host,
		TrueNASPort:          port,
		TrueNASAPIKey:        apiKey,
		TrueNASTLSSkipVerify: tlsSkipVerify,
		ListenAddr:           listenAddr,
	}, nil
}
