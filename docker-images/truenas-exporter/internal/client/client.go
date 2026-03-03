package client

import (
	"bytes"
	"context"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"time"
)

// Client communicates with the TrueNAS REST API.
type Client struct {
	baseURL    string
	apiKey     string
	httpClient *http.Client
}

// New creates a new TrueNAS API client.
func New(host string, port int, apiKey string, tlsSkipVerify bool) *Client {
	transport := &http.Transport{
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: tlsSkipVerify, //nolint:gosec // Operator opt-in via TRUENAS_TLS_SKIP_VERIFY
		},
	}
	return NewWithHTTPClient(host, port, apiKey, &http.Client{
		Transport: transport,
		Timeout:   30 * time.Second,
	})
}

// NewWithHTTPClient creates a new TrueNAS API client with the given http.Client (useful for testing).
func NewWithHTTPClient(host string, port int, apiKey string, httpClient *http.Client) *Client {
	hostPort := net.JoinHostPort(host, fmt.Sprintf("%d", port))
	return &Client{
		baseURL:    fmt.Sprintf("https://%s/api/v2.0", hostPort),
		apiKey:     apiKey,
		httpClient: httpClient,
	}
}

func (c *Client) doGet(ctx context.Context, path string, result any) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+path, nil)
	if err != nil {
		return fmt.Errorf("creating request for %s: %w", path, err)
	}
	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	req.Header.Set("Accept", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("requesting %s: %w", path, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status %d for %s", resp.StatusCode, path)
	}

	if err := json.NewDecoder(resp.Body).Decode(result); err != nil {
		return fmt.Errorf("decoding response for %s: %w", path, err)
	}
	return nil
}

func (c *Client) doPost(ctx context.Context, path string, body any, result any) error {
	var bodyBytes []byte
	var err error
	if body != nil {
		bodyBytes, err = json.Marshal(body)
		if err != nil {
			return fmt.Errorf("marshalling body for %s: %w", path, err)
		}
	} else {
		bodyBytes = []byte("{}")
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+path, bytes.NewReader(bodyBytes))
	if err != nil {
		return fmt.Errorf("creating request for %s: %w", path, err)
	}
	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	req.Header.Set("Accept", "application/json")
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("requesting %s: %w", path, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status %d for %s", resp.StatusCode, path)
	}

	if err := json.NewDecoder(resp.Body).Decode(result); err != nil {
		return fmt.Errorf("decoding response for %s: %w", path, err)
	}
	return nil
}

func (c *Client) GetPools(ctx context.Context) ([]Pool, error) {
	var pools []Pool
	if err := c.doGet(ctx, "/pool", &pools); err != nil {
		return nil, err
	}
	return pools, nil
}

// GetDatasets returns a flat list of all datasets using extra.flat=true
// so that every dataset appears exactly once without nested children.
func (c *Client) GetDatasets(ctx context.Context) ([]Dataset, error) {
	var datasets []Dataset
	if err := c.doGet(ctx, "/pool/dataset?extra.flat=true", &datasets); err != nil {
		return nil, err
	}
	return datasets, nil
}

func (c *Client) GetISCSISessions(ctx context.Context) ([]ISCSISession, error) {
	var sessions []ISCSISession
	if err := c.doPost(ctx, "/iscsi/global/sessions", nil, &sessions); err != nil {
		return nil, err
	}
	return sessions, nil
}

func (c *Client) GetISCSITargets(ctx context.Context) ([]ISCSITarget, error) {
	var targets []ISCSITarget
	if err := c.doGet(ctx, "/iscsi/target", &targets); err != nil {
		return nil, err
	}
	return targets, nil
}

func (c *Client) GetISCSIExtents(ctx context.Context) ([]ISCSIExtent, error) {
	var extents []ISCSIExtent
	if err := c.doGet(ctx, "/iscsi/extent", &extents); err != nil {
		return nil, err
	}
	return extents, nil
}

func (c *Client) GetDisks(ctx context.Context) ([]Disk, error) {
	var disks []Disk
	if err := c.doGet(ctx, "/disk", &disks); err != nil {
		return nil, err
	}
	return disks, nil
}

// GetDiskTemperatures returns a map of disk name to temperature in Celsius.
// Uses POST /disk/temperatures (the /disk endpoint does not include temperature).
func (c *Client) GetDiskTemperatures(ctx context.Context) (map[string]float64, error) {
	var temps map[string]float64
	if err := c.doPost(ctx, "/disk/temperatures", nil, &temps); err != nil {
		return nil, err
	}
	return temps, nil
}

func (c *Client) GetSystemInfo(ctx context.Context) (*SystemInfo, error) {
	var info SystemInfo
	if err := c.doGet(ctx, "/system/info", &info); err != nil {
		return nil, err
	}
	return &info, nil
}

func (c *Client) GetAlerts(ctx context.Context) ([]Alert, error) {
	var alerts []Alert
	if err := c.doGet(ctx, "/alert/list", &alerts); err != nil {
		return nil, err
	}
	return alerts, nil
}
