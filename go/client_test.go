package noosh24

import (
	"context"
	"errors"
	"net/http"
	"slices"
	"strings"
	"testing"
	"time"
)

func TestSendsKeyAndHeadersToDefaultBaseURL(t *testing.T) {
	m := newMock(t)
	m.json(200, data(map[string]any{
		"restaurant":   map[string]any{"id": "r1", "name": "Masago", "slug": "masago"},
		"key":          map[string]any{"id": "k1", "name": "Wolt", "prefix": "nsk_Ab3dE9xQ", "scopes": []string{"menu:read", "orders:read"}},
		"subscription": map[string]any{"status": "active", "modules": []string{"loyalty"}},
		"features":     map[string]any{"loyalty": true, "inventory": false},
	}))

	me := must(m.client().Whoami(ctx()))

	r := m.last()
	equal(t, r.Method, "GET")
	equal(t, r.URL.String(), "https://open-api.noosh24.com/v1/whoami")
	equal(t, r.Header.Get("Authorization"), "Bearer nsk_test_123")
	equal(t, r.Header.Get("Accept"), "application/json")
	equal(t, r.Header.Get("User-Agent"), "noosh24-go/"+Version)
	equal(t, r.Header.Get("Content-Type"), "")
	equal(t, len(r.Body), 0)
	equal(t, me.Restaurant.Name, "Masago")
	if !slices.Equal(me.Key.Scopes, []string{"menu:read", "orders:read"}) {
		t.Fatalf("scopes = %v", me.Key.Scopes)
	}
	equal(t, me.Subscription.Status, SubscriptionStatusActive)
	equal(t, me.Features.Loyalty, true)
	equal(t, me.Features.Inventory, false)
	if !strings.Contains(string(me.RawJSON), `"slug":"masago"`) {
		t.Fatalf("raw JSON = %s", me.RawJSON)
	}
}

func TestCustomBaseURLAndUserAgent(t *testing.T) {
	m := newMock(t)
	c := m.client(WithBaseURL("http://localhost:8080/v1/"), WithUserAgent("acme-pos/2.1"))
	m.json(200, data(map[string]any{}))

	must(c.Whoami(ctx()))

	equal(t, m.last().URL.String(), "http://localhost:8080/v1/whoami")
	equal(t, m.last().Header.Get("User-Agent"), "acme-pos/2.1 noosh24-go/"+Version)
}

func TestRejectsEmptyKey(t *testing.T) {
	for _, key := range []string{"", "  "} {
		c, err := NewClient(key)
		if c != nil || !errors.Is(err, ErrInvalidArgument) {
			t.Fatalf("NewClient(%q) = %v, %v", key, c, err)
		}
	}
	if _, err := NewClient("nsk_x", WithBaseURL("not a url")); !errors.Is(err, ErrInvalidArgument) {
		t.Fatalf("bad base URL accepted: %v", err)
	}
}

func TestDefaults(t *testing.T) {
	c, err := NewClient("nsk_x")
	if err != nil {
		t.Fatal(err)
	}
	equal(t, c.baseURL, DefaultBaseURL)
	equal(t, c.timeout, 30*time.Second)
	equal(t, c.maxRetries, 2)
	if c.Menu == nil || c.Reviews == nil {
		t.Fatal("resource groups are not set")
	}
}

func TestRetriesRateLimitAfterRetryAfter(t *testing.T) {
	m := newMock(t)
	m.json(429, map[string]any{"error": "rate_limit_exceeded", "message": "slow down"}, map[string]string{"Retry-After": "3"})
	m.json(200, items())

	tables := must(m.client().Tables.List(ctx()))

	equal(t, len(tables), 0)
	equal(t, len(m.all()), 2)
	if !slices.Equal(m.slept(), []time.Duration{3 * time.Second}) {
		t.Fatalf("slept %v", m.slept())
	}
}

func TestGivesUpAfterMaxRetries(t *testing.T) {
	m := newMock(t)
	c := m.client(WithMaxRetries(1))
	m.json(429, map[string]any{"error": "rate_limit_exceeded", "message": "slow down"}, map[string]string{"Retry-After": "1"})
	m.json(429, map[string]any{"error": "rate_limit_exceeded", "message": "slow down"}, map[string]string{"Retry-After": "7"})

	_, err := c.Tables.List(ctx())

	if !IsRateLimited(err) {
		t.Fatalf("err = %v", err)
	}
	apiErr, _ := AsAPIError(err)
	equal(t, apiErr.Status, 429)
	equal(t, apiErr.Code, CodeRateLimitExceeded)
	equal(t, apiErr.Kind, KindRateLimit)
	equal(t, apiErr.Message, "slow down")
	wait, ok := apiErr.RetryAfter()
	equal(t, ok, true)
	equal(t, wait, 7*time.Second)
	equal(t, apiErr.Header.Get("retry-after"), "7")
	equal(t, len(m.all()), 2)
}

func TestDoesNotWaitLongerThanAMinute(t *testing.T) {
	m := newMock(t)
	m.json(429, map[string]any{"error": "rate_limit_exceeded"}, map[string]string{"Retry-After": "120"})

	_, err := m.client().Tables.List(ctx())

	if !IsRateLimited(err) {
		t.Fatalf("err = %v", err)
	}
	apiErr, _ := AsAPIError(err)
	equal(t, apiErr.Message, "rate_limit_exceeded")
	equal(t, len(m.all()), 1)
	equal(t, len(m.slept()), 0)
}

func TestRetryAfterWithoutHeader(t *testing.T) {
	_, ok := (&APIError{Header: http.Header{}}).RetryAfter()
	equal(t, ok, false)
	wait, ok := (&APIError{Header: http.Header{"Retry-After": {"2.9"}}}).RetryAfter()
	equal(t, ok, true)
	equal(t, wait, 2*time.Second)
}

func TestBacksOffOnTemporarilyUnavailable(t *testing.T) {
	m := newMock(t)
	for range 3 {
		m.json(503, map[string]any{"error": "temporarily_unavailable", "message": "try again"})
	}

	_, err := m.client().Tables.ListHalls(ctx())

	if !IsTemporarilyUnavailable(err) || !IsServerError(err) {
		t.Fatalf("err = %v", err)
	}
	equal(t, len(m.all()), 3)
	if !slices.Equal(m.slept(), []time.Duration{500 * time.Millisecond, time.Second}) {
		t.Fatalf("slept %v", m.slept())
	}
}

func TestBackoffSequence(t *testing.T) {
	got := []time.Duration{backoff(0), backoff(1), backoff(2), backoff(3), backoff(4), backoff(10)}
	want := []time.Duration{500 * time.Millisecond, time.Second, 2 * time.Second, 4 * time.Second, 8 * time.Second, 8 * time.Second}
	if !slices.Equal(got, want) {
		t.Fatalf("backoff = %v", got)
	}
}

func TestRetriesConnectionErrorsOnReads(t *testing.T) {
	m := newMock(t)
	c := m.client(WithMaxRetries(1))
	reset := errors.New("connection reset")
	m.fail(reset)
	m.json(200, items(map[string]any{"id": "h1", "name": "Main", "position": 1}))

	halls := must(c.Tables.ListHalls(ctx()))
	equal(t, halls[0].Name, "Main")
	equal(t, len(m.slept()), 1)

	m.fail(reset).fail(reset)
	_, err := c.Tables.ListHalls(ctx())
	if !errors.Is(err, ErrConnection) || errors.Is(err, ErrTimeout) {
		t.Fatalf("err = %v", err)
	}
	if !errors.Is(err, reset) || !strings.Contains(err.Error(), "connection reset") {
		t.Fatalf("err = %v", err)
	}
	var connErr *ConnectionError
	if !errors.As(err, &connErr) || connErr.Timeout {
		t.Fatalf("err = %#v", err)
	}
}

func TestTimeout(t *testing.T) {
	m := newMock(t)
	c := m.client(WithMaxRetries(0), WithTimeout(50*time.Millisecond))
	m.slow(2*time.Second, 200, `{"data":{}}`)

	start := time.Now()
	_, err := c.Whoami(ctx())

	if !errors.Is(err, ErrTimeout) || !errors.Is(err, ErrConnection) {
		t.Fatalf("err = %v", err)
	}
	if time.Since(start) > time.Second {
		t.Fatalf("took %s", time.Since(start))
	}
}

func TestTimeoutIsRetried(t *testing.T) {
	m := newMock(t)
	c := m.client(WithMaxRetries(1), WithTimeout(50*time.Millisecond))
	m.slow(2*time.Second, 200, `{"data":{}}`)
	m.json(200, data(map[string]any{"restaurant": map[string]any{"name": "Masago"}}))

	me := must(c.Whoami(ctx()))

	equal(t, me.Restaurant.Name, "Masago")
	equal(t, len(m.all()), 2)
}

func TestCancelledContextIsNotRetried(t *testing.T) {
	m := newMock(t)
	c := m.client()
	cancelled, cancel := context.WithCancel(ctx())
	cancel()
	m.fail(context.Canceled)

	_, err := c.Whoami(cancelled)

	if !errors.Is(err, context.Canceled) {
		t.Fatalf("err = %v", err)
	}
	equal(t, len(m.slept()), 0)
}

func TestBodyThatIsNotJSONIsAnAPIError(t *testing.T) {
	m := newMock(t)
	m.raw(200, "<html>gateway</html>")

	_, err := m.client().Whoami(ctx())

	apiErr, ok := AsAPIError(err)
	if !ok {
		t.Fatalf("err = %v", err)
	}
	equal(t, apiErr.Status, 200)
	equal(t, apiErr.Kind, KindAPI)
	equal(t, apiErr.Body, "<html>gateway</html>")
	equal(t, apiErr.Message, "The API answered with a body that is not JSON")
}

func TestBodyWithoutDataIsAnAPIError(t *testing.T) {
	m := newMock(t)
	m.raw(200, `{"items":[]}`)

	_, err := m.client().Tables.List(ctx())

	apiErr, ok := AsAPIError(err)
	if !ok {
		t.Fatalf("err = %v", err)
	}
	equal(t, apiErr.Message, `The API answered without a "data" field`)
}

func TestBuildsRepeatedQueryParameters(t *testing.T) {
	got := encodeQuery([]queryPair{{"sort", "price desc"}, {"sort", "name asc"}, {"where", "a = 1"}, {"available", "true"}})
	equal(t, got, "sort=price%20desc&sort=name%20asc&where=a%20%3D%201&available=true")
}

func TestPathID(t *testing.T) {
	got, err := pathID("a/b c")
	equal(t, got, "a%2Fb%20c")
	equal(t, err, nil)
	got, _ = pathID("Plov-1_2.3~ş")
	equal(t, got, "Plov-1_2.3~%C5%9F")
	if _, err := pathID(" "); !errors.Is(err, ErrInvalidArgument) {
		t.Fatalf("err = %v", err)
	}
}

func TestDefaultSleepHonoursContext(t *testing.T) {
	cancelled, cancel := context.WithCancel(ctx())
	cancel()
	if err := sleepContext(cancelled, time.Hour); !errors.Is(err, context.Canceled) {
		t.Fatalf("err = %v", err)
	}
	if err := sleepContext(ctx(), time.Millisecond); err != nil {
		t.Fatalf("err = %v", err)
	}
}

func TestEmptySuccessBodyGivesEmptyModel(t *testing.T) {
	m := newMock(t)
	m.raw(200, "")

	me := must(m.client().Whoami(ctx()))

	if me.Restaurant != nil {
		t.Fatalf("restaurant = %#v", me.Restaurant)
	}
}
