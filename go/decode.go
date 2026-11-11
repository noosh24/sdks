package noosh24

import (
	"bytes"
	"encoding/json"
	"math"
	"strconv"
	"strings"
	"time"
)

type decodable[T any] interface {
	*T
	json.Unmarshaler
}

func objectFields(data []byte) (map[string]json.RawMessage, bool) {
	if !isObject(data) {
		return nil, false
	}
	var f map[string]json.RawMessage
	if err := json.Unmarshal(data, &f); err != nil {
		return nil, false
	}
	return f, true
}

func isObject(data []byte) bool {
	data = bytes.TrimSpace(data)
	return len(data) > 0 && data[0] == '{'
}

func cloneRaw(data []byte) json.RawMessage {
	return json.RawMessage(bytes.Clone(bytes.TrimSpace(data)))
}

func scalarText(raw json.RawMessage) (string, bool) {
	raw = bytes.TrimSpace(raw)
	if len(raw) == 0 {
		return "", false
	}
	switch raw[0] {
	case '"':
		var s string
		if err := json.Unmarshal(raw, &s); err != nil {
			return "", false
		}
		return s, true
	case 't', 'f':
		var b bool
		if err := json.Unmarshal(raw, &b); err != nil {
			return "", false
		}
		return strconv.FormatBool(b), true
	case 'n', '{', '[':
		return "", false
	default:
		return string(raw), true
	}
}

func number(raw json.RawMessage) (float64, bool) {
	raw = bytes.TrimSpace(raw)
	if len(raw) == 0 || raw[0] == '"' || raw[0] == 't' || raw[0] == 'f' || raw[0] == 'n' || raw[0] == '{' || raw[0] == '[' {
		return 0, false
	}
	v, err := strconv.ParseFloat(string(raw), 64)
	if err != nil || math.IsNaN(v) || math.IsInf(v, 0) {
		return 0, false
	}
	return v, true
}

func stringPtr(raw json.RawMessage) *string {
	s, ok := scalarText(raw)
	if !ok {
		return nil
	}
	return &s
}

func stringValue(raw json.RawMessage) string {
	s, _ := scalarText(raw)
	return s
}

func intPtr(raw json.RawMessage) *int {
	text := string(bytes.TrimSpace(raw))
	if i, err := strconv.ParseInt(text, 10, 0); err == nil {
		v := int(i)
		return &v
	}
	f, ok := number(raw)
	if !ok || f > math.MaxInt64 || f < math.MinInt64 {
		return nil
	}
	v := int(f)
	return &v
}

func intValue(raw json.RawMessage) int {
	if v := intPtr(raw); v != nil {
		return *v
	}
	return 0
}

func floatPtr(raw json.RawMessage) *float64 {
	f, ok := number(raw)
	if !ok {
		return nil
	}
	return &f
}

func floatValue(raw json.RawMessage) float64 {
	f, _ := number(raw)
	return f
}

func boolPtr(raw json.RawMessage) *bool {
	raw = bytes.TrimSpace(raw)
	if len(raw) == 0 {
		return nil
	}
	var v bool
	switch raw[0] {
	case 't', 'f':
		if err := json.Unmarshal(raw, &v); err != nil {
			return nil
		}
	case '"':
		s, _ := scalarText(raw)
		v = s != ""
	case 'n', '{', '[':
		return nil
	default:
		f, ok := number(raw)
		if !ok {
			return nil
		}
		v = f != 0
	}
	return &v
}

func boolValue(raw json.RawMessage) bool {
	if v := boolPtr(raw); v != nil {
		return *v
	}
	return false
}

var timeLayouts = []string{
	time.RFC3339Nano,
	"2006-01-02T15:04:05.999999999",
	"2006-01-02 15:04:05.999999999Z07:00",
	"2006-01-02 15:04:05.999999999",
	"2006-01-02",
}

func parseTime(text string) (time.Time, bool) {
	text = strings.ToUpper(strings.TrimSpace(text))
	if text == "" {
		return time.Time{}, false
	}
	for _, layout := range timeLayouts {
		if t, err := time.Parse(layout, text); err == nil {
			return t, true
		}
	}
	return time.Time{}, false
}

func timePtr(raw json.RawMessage) *time.Time {
	raw = bytes.TrimSpace(raw)
	if len(raw) == 0 || raw[0] != '"' {
		return nil
	}
	s, _ := scalarText(raw)
	t, ok := parseTime(s)
	if !ok {
		return nil
	}
	return &t
}

func timeValue(raw json.RawMessage) time.Time {
	if t := timePtr(raw); t != nil {
		return *t
	}
	return time.Time{}
}

func rawList(raw json.RawMessage) []json.RawMessage {
	raw = bytes.TrimSpace(raw)
	if len(raw) == 0 || raw[0] != '[' {
		return nil
	}
	var items []json.RawMessage
	if err := json.Unmarshal(raw, &items); err != nil {
		return nil
	}
	return items
}

func stringList(raw json.RawMessage) []string {
	items := rawList(raw)
	if items == nil {
		return nil
	}
	out := make([]string, 0, len(items))
	for _, item := range items {
		if s, ok := scalarText(item); ok {
			out = append(out, s)
		}
	}
	return out
}

func floatMap(raw json.RawMessage) map[string]float64 {
	f, ok := objectFields(raw)
	if !ok {
		return nil
	}
	out := make(map[string]float64, len(f))
	for k, v := range f {
		if n, ok := number(v); ok {
			out[k] = n
		}
	}
	return out
}

func object[T any, P decodable[T]](raw json.RawMessage) *T {
	if !isObject(raw) {
		return nil
	}
	v := new(T)
	if err := P(v).UnmarshalJSON(raw); err != nil {
		return nil
	}
	return v
}

func listOf[T any, P decodable[T]](raw json.RawMessage) []T {
	items := rawList(raw)
	if items == nil {
		return nil
	}
	return decodeItems[T, P](items)
}

func decodeItems[T any, P decodable[T]](items []json.RawMessage) []T {
	out := make([]T, 0, len(items))
	for _, item := range items {
		if v := object[T, P](item); v != nil {
			out = append(out, *v)
		}
	}
	return out
}

func mapOf[T any, P decodable[T]](raw json.RawMessage) map[string]T {
	f, ok := objectFields(raw)
	if !ok {
		return nil
	}
	out := make(map[string]T, len(f))
	for k, item := range f {
		if v := object[T, P](item); v != nil {
			out[k] = *v
		}
	}
	return out
}
