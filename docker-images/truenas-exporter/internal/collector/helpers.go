package collector

import (
	"strconv"
)

// toFloat64 converts a parsed JSON value (typically float64, json.Number, or string) to float64.
func toFloat64(v any) (float64, bool) {
	switch val := v.(type) {
	case float64:
		return val, true
	case int:
		return float64(val), true
	case int64:
		return float64(val), true
	case string:
		f, err := strconv.ParseFloat(val, 64)
		if err != nil {
			return 0, false
		}
		return f, true
	case nil:
		return 0, false
	default:
		return 0, false
	}
}
