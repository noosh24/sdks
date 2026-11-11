package noosh24

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const (
	Version           = "0.1.0"
	DefaultBaseURL    = "https://open-api.noosh24.com/v1"
	DefaultTimeout    = 30 * time.Second
	DefaultMaxRetries = 2
	maxRetryWait      = 60 * time.Second
	maxBackoff        = 8 * time.Second
	userAgentProduct  = "noosh24-go/" + Version
)

type Client struct {
	Menu         *MenuService
	Reservations *ReservationsService
	Orders       *OrdersService
	Payments     *PaymentsService
	Tables       *TablesService
	Customers    *CustomersService
	Loyalty      *LoyaltyService
	Stock        *StockService
	Reviews      *ReviewsService

	apiKey     string
	baseURL    string
	timeout    time.Duration
	maxRetries int
	userAgent  string
	httpClient *http.Client
	sleep      func(context.Context, time.Duration) error
}

type Option func(*Client)

func WithBaseURL(baseURL string) Option {
	return func(c *Client) { c.baseURL = baseURL }
}

func WithTimeout(timeout time.Duration) Option {
	return func(c *Client) { c.timeout = timeout }
}

func WithMaxRetries(maxRetries int) Option {
	return func(c *Client) { c.maxRetries = maxRetries }
}

func WithUserAgent(userAgent string) Option {
	return func(c *Client) {
		if strings.TrimSpace(userAgent) != "" {
			c.userAgent = userAgent + " " + userAgentProduct
		} else {
			c.userAgent = userAgentProduct
		}
	}
}

func WithHTTPClient(httpClient *http.Client) Option {
	return func(c *Client) { c.httpClient = httpClient }
}

func withSleep(sleep func(context.Context, time.Duration) error) Option {
	return func(c *Client) { c.sleep = sleep }
}

func NewClient(apiKey string, opts ...Option) (*Client, error) {
	key := strings.TrimSpace(apiKey)
	if key == "" {
		return nil, fmt.Errorf("%w: an API key is required", ErrInvalidArgument)
	}
	c := &Client{
		apiKey:     key,
		baseURL:    DefaultBaseURL,
		timeout:    DefaultTimeout,
		maxRetries: DefaultMaxRetries,
		userAgent:  userAgentProduct,
		sleep:      sleepContext,
	}
	for _, opt := range opts {
		if opt != nil {
			opt(c)
		}
	}
	c.baseURL = strings.TrimRight(strings.TrimSpace(c.baseURL), "/")
	if c.baseURL == "" {
		c.baseURL = DefaultBaseURL
	}
	if u, err := url.Parse(c.baseURL); err != nil || u.Scheme == "" || u.Host == "" {
		return nil, fmt.Errorf("%w: %q is not an absolute base URL", ErrInvalidArgument, c.baseURL)
	}
	c.maxRetries = max(0, c.maxRetries)
	c.timeout = max(0, c.timeout)
	if c.httpClient == nil {
		c.httpClient = &http.Client{
			CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
		}
	}
	if c.sleep == nil {
		c.sleep = sleepContext
	}
	c.Menu = &MenuService{c}
	c.Reservations = &ReservationsService{c}
	c.Orders = &OrdersService{c}
	c.Payments = &PaymentsService{c}
	c.Tables = &TablesService{c}
	c.Customers = &CustomersService{c}
	c.Loyalty = &LoyaltyService{c}
	c.Stock = &StockService{c}
	c.Reviews = &ReviewsService{c}
	return c, nil
}

func (c *Client) Whoami(ctx context.Context) (*Whoami, error) {
	return getOne[Whoami](ctx, c, "/whoami", nil)
}

type queryPair struct {
	name  string
	value string
}

type request struct {
	method    string
	path      string
	query     []queryPair
	body      any
	retryable bool
}

type response struct {
	status int
	data   json.RawMessage
}

func (c *Client) do(ctx context.Context, req request) (*response, error) {
	if ctx == nil {
		return nil, fmt.Errorf("%w: a context is required", ErrInvalidArgument)
	}
	target := c.baseURL + req.path
	if q := encodeQuery(req.query); q != "" {
		target += "?" + q
	}
	var payload []byte
	if req.body != nil {
		var buf bytes.Buffer
		enc := json.NewEncoder(&buf)
		enc.SetEscapeHTML(false)
		if err := enc.Encode(req.body); err != nil {
			return nil, fmt.Errorf("%w: %v", ErrInvalidArgument, err)
		}
		payload = bytes.TrimRight(buf.Bytes(), "\n")
	}
	for attempt := 0; ; attempt++ {
		resp, err := c.send(ctx, req.method, target, payload)
		if err != nil {
			var connErr *ConnectionError
			if errors.As(err, &connErr) && req.retryable && attempt < c.maxRetries && ctx.Err() == nil {
				if err := c.sleep(ctx, backoff(attempt)); err != nil {
					return nil, err
				}
				continue
			}
			return nil, err
		}
		if resp.status >= 200 && resp.status < 300 {
			data, err := decodeEnvelope(resp)
			if err != nil {
				return nil, err
			}
			return &response{status: resp.status, data: data}, nil
		}
		if wait, ok := retryWait(resp, attempt); ok && req.retryable && attempt < c.maxRetries {
			if err := c.sleep(ctx, wait); err != nil {
				return nil, err
			}
			continue
		}
		return nil, newAPIError(resp.status, resp.header, resp.body)
	}
}

type rawResponse struct {
	status int
	header http.Header
	body   []byte
}

func (c *Client) send(ctx context.Context, method, target string, payload []byte) (*rawResponse, error) {
	attemptCtx := ctx
	cancel := func() {}
	if c.timeout > 0 {
		attemptCtx, cancel = context.WithTimeout(ctx, c.timeout)
	}
	defer cancel()
	var body io.Reader
	if payload != nil {
		body = bytes.NewReader(payload)
	}
	httpReq, err := http.NewRequestWithContext(attemptCtx, method, target, body)
	if err != nil {
		return nil, fmt.Errorf("%w: %v", ErrInvalidArgument, err)
	}
	httpReq.Header.Set("Authorization", "Bearer "+c.apiKey)
	httpReq.Header.Set("Accept", "application/json")
	httpReq.Header.Set("User-Agent", c.userAgent)
	if payload != nil {
		httpReq.Header.Set("Content-Type", "application/json")
	}
	resp, err := c.httpClient.Do(httpReq)
	if err != nil {
		return nil, c.transportError(ctx, attemptCtx, err)
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, c.transportError(ctx, attemptCtx, err)
	}
	return &rawResponse{status: resp.StatusCode, header: resp.Header.Clone(), body: data}, nil
}

func (c *Client) transportError(ctx, attemptCtx context.Context, err error) error {
	if ctxErr := ctx.Err(); ctxErr != nil {
		if errors.Is(ctxErr, context.DeadlineExceeded) {
			return &ConnectionError{Timeout: true, Err: ctxErr}
		}
		return fmt.Errorf("noosh24: %w", ctxErr)
	}
	var netErr net.Error
	if errors.Is(attemptCtx.Err(), context.DeadlineExceeded) || (errors.As(err, &netErr) && netErr.Timeout()) {
		return &ConnectionError{Timeout: true, Err: fmt.Errorf("no answer within %s: %w", c.timeout, err)}
	}
	return &ConnectionError{Err: err}
}

func decodeEnvelope(resp *rawResponse) (json.RawMessage, error) {
	if len(bytes.TrimSpace(resp.body)) == 0 {
		return nil, nil
	}
	var envelope map[string]json.RawMessage
	if err := json.Unmarshal(resp.body, &envelope); err != nil {
		if !json.Valid(resp.body) {
			return nil, decodeError(resp, "The API answered with a body that is not JSON")
		}
		return nil, decodeError(resp, `The API answered without a "data" field`)
	}
	data, ok := envelope["data"]
	if !ok {
		return nil, decodeError(resp, `The API answered without a "data" field`)
	}
	return data, nil
}

func decodeError(resp *rawResponse, message string) *APIError {
	return &APIError{Status: resp.status, Message: message, Kind: KindAPI, Header: resp.header, Body: string(resp.body)}
}

func retryWait(resp *rawResponse, attempt int) (time.Duration, bool) {
	switch resp.status {
	case 429, 502, 503, 504:
	default:
		return 0, false
	}
	if seconds, ok := retryAfterSeconds(resp.header.Get("Retry-After")); ok {
		wait := time.Duration(seconds * float64(time.Second))
		if wait > maxRetryWait {
			return 0, false
		}
		return wait, true
	}
	return backoff(attempt), true
}

func backoff(attempt int) time.Duration {
	wait := time.Duration(float64(500*time.Millisecond) * math.Pow(2, float64(attempt)))
	return min(maxBackoff, wait)
}

func sleepContext(ctx context.Context, d time.Duration) error {
	if d <= 0 {
		return ctx.Err()
	}
	timer := time.NewTimer(d)
	defer timer.Stop()
	select {
	case <-timer.C:
		return nil
	case <-ctx.Done():
		return fmt.Errorf("noosh24: %w", ctx.Err())
	}
}

func encodeQuery(pairs []queryPair) string {
	var b strings.Builder
	for i, p := range pairs {
		if i > 0 {
			b.WriteByte('&')
		}
		b.WriteString(queryEscape(p.name))
		b.WriteByte('=')
		b.WriteString(queryEscape(p.value))
	}
	return b.String()
}

func queryEscape(s string) string {
	return strings.ReplaceAll(url.QueryEscape(s), "+", "%20")
}

func pathID(id string) (string, error) {
	if strings.TrimSpace(id) == "" {
		return "", fmt.Errorf("%w: an id is required", ErrInvalidArgument)
	}
	const hex = "0123456789ABCDEF"
	var b strings.Builder
	for i := 0; i < len(id); i++ {
		ch := id[i]
		if ch >= 'A' && ch <= 'Z' || ch >= 'a' && ch <= 'z' || ch >= '0' && ch <= '9' || ch == '-' || ch == '_' || ch == '.' || ch == '~' {
			b.WriteByte(ch)
			continue
		}
		b.WriteByte('%')
		b.WriteByte(hex[ch>>4])
		b.WriteByte(hex[ch&15])
	}
	return b.String(), nil
}
