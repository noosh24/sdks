package noosh24

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"sync"
	"testing"
	"time"
)

type reply struct {
	status int
	body   string
	header map[string]string
	err    error
	delay  time.Duration
}

type recorded struct {
	Method string
	URL    *url.URL
	Header http.Header
	Body   []byte
}

func (r recorded) query() url.Values {
	return r.URL.Query()
}

func (r recorded) json(t *testing.T) map[string]any {
	t.Helper()
	var out map[string]any
	if err := json.Unmarshal(r.Body, &out); err != nil {
		t.Fatalf("request body is not JSON: %v (%q)", err, r.Body)
	}
	return out
}

type mockAPI struct {
	t        *testing.T
	mu       sync.Mutex
	queue    []reply
	requests []recorded
	sleeps   []time.Duration
	server   *httptest.Server
	upstream http.RoundTripper
}

func newMock(t *testing.T) *mockAPI {
	t.Helper()
	m := &mockAPI{t: t}
	m.server = httptest.NewServer(http.HandlerFunc(m.serve))
	m.upstream = m.server.Client().Transport
	t.Cleanup(m.server.Close)
	return m
}

func (m *mockAPI) json(status int, body any, header ...map[string]string) *mockAPI {
	m.t.Helper()
	data, err := json.Marshal(body)
	if err != nil {
		m.t.Fatal(err)
	}
	r := reply{status: status, body: string(data)}
	if len(header) > 0 {
		r.header = header[0]
	}
	m.mu.Lock()
	m.queue = append(m.queue, r)
	m.mu.Unlock()
	return m
}

func (m *mockAPI) raw(status int, body string) *mockAPI {
	m.mu.Lock()
	m.queue = append(m.queue, reply{status: status, body: body})
	m.mu.Unlock()
	return m
}

func (m *mockAPI) slow(delay time.Duration, status int, body string) *mockAPI {
	m.mu.Lock()
	m.queue = append(m.queue, reply{status: status, body: body, delay: delay})
	m.mu.Unlock()
	return m
}

func (m *mockAPI) fail(err error) *mockAPI {
	m.mu.Lock()
	m.queue = append(m.queue, reply{err: err})
	m.mu.Unlock()
	return m
}

func (m *mockAPI) RoundTrip(req *http.Request) (*http.Response, error) {
	var body []byte
	if req.Body != nil {
		body, _ = io.ReadAll(req.Body)
		_ = req.Body.Close()
	}
	u := *req.URL
	m.mu.Lock()
	m.requests = append(m.requests, recorded{Method: req.Method, URL: &u, Header: req.Header.Clone(), Body: body})
	if len(m.queue) == 0 {
		m.mu.Unlock()
		m.t.Errorf("no response queued for %s %s", req.Method, req.URL)
		return nil, io.ErrUnexpectedEOF
	}
	if next := m.queue[0]; next.err != nil {
		m.queue = m.queue[1:]
		m.mu.Unlock()
		return nil, next.err
	}
	m.mu.Unlock()
	target, _ := url.Parse(m.server.URL)
	forward := req.Clone(req.Context())
	forward.URL.Scheme = target.Scheme
	forward.URL.Host = target.Host
	forward.Host = target.Host
	forward.Body = nil
	forward.ContentLength = 0
	if len(body) > 0 {
		forward.Body = io.NopCloser(bytes.NewReader(body))
		forward.ContentLength = int64(len(body))
	}
	return m.upstream.RoundTrip(forward)
}

func (m *mockAPI) serve(w http.ResponseWriter, r *http.Request) {
	m.mu.Lock()
	next := m.queue[0]
	m.queue = m.queue[1:]
	m.mu.Unlock()
	if next.delay > 0 {
		select {
		case <-time.After(next.delay):
		case <-r.Context().Done():
			return
		}
	}
	for k, v := range next.header {
		w.Header().Set(k, v)
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(next.status)
	_, _ = io.WriteString(w, next.body)
}

func (m *mockAPI) last() recorded {
	m.mu.Lock()
	defer m.mu.Unlock()
	if len(m.requests) == 0 {
		m.t.Fatal("no request was sent")
	}
	return m.requests[len(m.requests)-1]
}

func (m *mockAPI) all() []recorded {
	m.mu.Lock()
	defer m.mu.Unlock()
	return append([]recorded(nil), m.requests...)
}

func (m *mockAPI) client(opts ...Option) *Client {
	m.t.Helper()
	base := []Option{
		WithHTTPClient(&http.Client{Transport: m}),
		withSleep(func(_ context.Context, d time.Duration) error {
			m.mu.Lock()
			m.sleeps = append(m.sleeps, d)
			m.mu.Unlock()
			return nil
		}),
	}
	c, err := NewClient("nsk_test_123", append(base, opts...)...)
	if err != nil {
		m.t.Fatal(err)
	}
	return c
}

func (m *mockAPI) slept() []time.Duration {
	m.mu.Lock()
	defer m.mu.Unlock()
	return append([]time.Duration(nil), m.sleeps...)
}

func page(items []map[string]any, total, limit, offset int) map[string]any {
	if items == nil {
		items = []map[string]any{}
	}
	return map[string]any{"data": map[string]any{"items": items, "total": total, "limit": limit, "offset": offset}}
}

func data(v any) map[string]any {
	return map[string]any{"data": v}
}

func items(list ...map[string]any) map[string]any {
	if list == nil {
		list = []map[string]any{}
	}
	return map[string]any{"data": map[string]any{"items": list, "total": len(list)}}
}

func ctx() context.Context {
	return context.Background()
}

func must[T any](v T, err error) T {
	if err != nil {
		panic(fmt.Sprintf("unexpected error: %v", err))
	}
	return v
}

func equal[T comparable](t *testing.T, got, want T) {
	t.Helper()
	if got != want {
		t.Fatalf("got %#v, want %#v", got, want)
	}
}
