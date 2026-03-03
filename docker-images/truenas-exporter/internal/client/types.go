package client

// Pool represents a ZFS pool from GET /pool.
type Pool struct {
	ID     int    `json:"id"`
	Name   string `json:"name"`
	Status string `json:"status"`
}

// Dataset represents a dataset/zvol from GET /pool/dataset?extra.flat=true.
type Dataset struct {
	ID            string    `json:"id"`
	Name          string    `json:"name"`
	Type          string    `json:"type"`
	Used          *DSVal    `json:"used"`
	Available     *DSVal    `json:"available"`
	VolSize       *DSVal    `json:"volsize"`
	Quota         *DSVal    `json:"quota"`
	CompressRatio *DSVal    `json:"compressratio"`
	Children      []Dataset `json:"children"`
}

// DSVal represents a dataset property value with parsed/rawvalue.
type DSVal struct {
	Parsed   any    `json:"parsed"`
	Value    any    `json:"value"`
	RawValue string `json:"rawvalue"`
}

// ISCSISession represents a session from POST /iscsi/global/sessions.
type ISCSISession struct {
	Initiator   string `json:"initiator"`
	TargetAlias string `json:"target_alias"`
}

// ISCSITarget represents a target from GET /iscsi/target.
type ISCSITarget struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

// ISCSIExtent represents an extent from GET /iscsi/extent.
type ISCSIExtent struct {
	ID      int    `json:"id"`
	Name    string `json:"name"`
	Disk    string `json:"disk"`
	Enabled bool   `json:"enabled"`
}

// Disk represents a disk from GET /disk (temperature is fetched separately via POST /disk/temperatures).
type Disk struct {
	Name   string `json:"name"`
	Serial string `json:"serial"`
	Model  string `json:"model"`
	Size   int64  `json:"size"`
}

// SystemInfo represents system information from GET /system/info.
type SystemInfo struct {
	Version       string  `json:"version"`
	Hostname      string  `json:"hostname"`
	UptimeSeconds float64 `json:"uptime_seconds"`
}

// Alert represents an alert from GET /alert/list.
type Alert struct {
	Level     string `json:"level"`
	Dismissed bool   `json:"dismissed"`
}
