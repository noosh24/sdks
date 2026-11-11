package noosh24

import (
	"errors"
	"fmt"
	"strings"
	"testing"
)

func TestMapsErrorCodes(t *testing.T) {
	cases := []struct {
		status int
		code   string
		kind   ErrorKind
		parent ErrorKind
		is     func(error) bool
	}{
		{400, "validation_error", KindValidation, KindAPI, IsValidation},
		{401, "no_api_key", KindNoAPIKey, KindAuthentication, IsNoAPIKey},
		{401, "invalid_api_key", KindInvalidAPIKey, KindAuthentication, IsInvalidAPIKey},
		{403, "insufficient_scope", KindInsufficientScope, KindPermissionDenied, IsInsufficientScope},
		{403, "module_not_enabled", KindModuleNotEnabled, KindPermissionDenied, IsModuleNotEnabled},
		{403, "venue_suspended", KindVenueSuspended, KindPermissionDenied, IsVenueSuspended},
		{403, "not_your_reservation", KindNotYourReservation, KindPermissionDenied, IsNotYourReservation},
		{404, "not_found", KindNotFound, KindAPI, IsNotFound},
		{404, "table_not_found", KindTableNotFound, KindNotFound, IsTableNotFound},
		{409, "table_taken", KindTableTaken, KindConflict, IsTableTaken},
		{409, "cannot_cancel", KindCannotCancel, KindConflict, IsCannotCancel},
		{422, "outside_hours", KindOutsideHours, KindUnprocessable, IsOutsideHours},
		{422, "in_the_past", KindInThePast, KindUnprocessable, IsInThePast},
		{422, "table_too_small", KindTableTooSmall, KindUnprocessable, IsTableTooSmall},
		{429, "rate_limit_exceeded", KindRateLimit, KindAPI, IsRateLimited},
		{503, "temporarily_unavailable", KindTemporarilyUnavailable, KindServer, IsTemporarilyUnavailable},
		{403, "something_new", KindPermissionDenied, KindAPI, IsPermissionDenied},
		{409, "something_new", KindConflict, KindAPI, IsConflict},
		{500, "query_failed", KindServer, KindAPI, IsServerError},
		{418, "", KindAPI, "", func(err error) bool { _, ok := AsAPIError(err); return ok }},
	}
	parents := map[ErrorKind]func(error) bool{
		KindAPI:              func(err error) bool { _, ok := AsAPIError(err); return ok },
		KindAuthentication:   IsAuthentication,
		KindPermissionDenied: IsPermissionDenied,
		KindNotFound:         IsNotFound,
		KindConflict:         IsConflict,
		KindUnprocessable:    IsUnprocessable,
		KindServer:           IsServerError,
	}
	for _, tc := range cases {
		t.Run(fmt.Sprintf("%d %s", tc.status, tc.code), func(t *testing.T) {
			m := newMock(t)
			c := m.client(WithMaxRetries(0))
			if tc.code == "" {
				m.json(tc.status, map[string]any{"nope": true})
			} else {
				m.json(tc.status, map[string]any{"error": tc.code, "message": "Mesaj"})
			}

			_, err := c.Customers.Get(ctx(), "c1")

			apiErr, ok := AsAPIError(err)
			if !ok {
				t.Fatalf("err = %v", err)
			}
			equal(t, apiErr.Kind, tc.kind)
			equal(t, apiErr.Kind.Parent(), tc.parent)
			equal(t, apiErr.Status, tc.status)
			equal(t, apiErr.Code, tc.code)
			if tc.code == "" {
				equal(t, apiErr.Message, fmt.Sprintf("HTTP %d", tc.status))
			} else {
				equal(t, apiErr.Message, "Mesaj")
			}
			if !tc.is(err) {
				t.Fatalf("predicate for %s is false", tc.kind)
			}
			if tc.parent != "" && !parents[tc.parent](err) {
				t.Fatalf("parent predicate for %s is false", tc.parent)
			}
			if !apiErr.Kind.Is(KindAPI) {
				t.Fatal("kind is not under APIError")
			}
			if errors.Is(err, ErrConnection) {
				t.Fatal("API error looks like a connection error")
			}
			if !strings.HasPrefix(err.Error(), "noosh24: ") {
				t.Fatalf("Error() = %q", err.Error())
			}
		})
	}
}

func TestPredicatesSeeThroughWrapping(t *testing.T) {
	err := fmt.Errorf("booking: %w", &APIError{Status: 409, Code: CodeTableTaken, Kind: KindTableTaken})
	if !IsTableTaken(err) || !IsConflict(err) || IsCannotCancel(err) || IsNotFound(err) {
		t.Fatal("predicates do not follow the wrapped error")
	}
	if IsTableTaken(errors.New("plain")) || IsTableTaken(nil) {
		t.Fatal("predicate matched a non-API error")
	}
}

func TestValidationErrorIsNotRetried(t *testing.T) {
	m := newMock(t)
	m.json(400, map[string]any{"error": "validation_error", "message": `"nope" is not a filterable field on this resource`})

	_, err := m.client().Menu.ListProducts(ctx(), &ListParams{Where: RawWhere("nope = 1")})

	if !IsValidation(err) || !strings.Contains(err.Error(), "not a filterable field") {
		t.Fatalf("err = %v", err)
	}
	equal(t, len(m.all()), 1)
}

func TestMissingMessageFallsBackToCode(t *testing.T) {
	err := newAPIError(404, nil, []byte(`{"error":"not_found"}`))
	equal(t, err.Message, "not_found")
	equal(t, err.Error(), "noosh24: not_found (HTTP 404 not_found)")
	err = newAPIError(502, nil, []byte(`Bad gateway`))
	equal(t, err.Message, "HTTP 502")
	equal(t, err.Kind, KindServer)
}
