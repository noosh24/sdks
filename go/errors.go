package noosh24

import (
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net/http"
	"strconv"
	"strings"
	"time"
)

var (
	ErrInvalidArgument = errors.New("noosh24: invalid argument")
	ErrConnection      = errors.New("noosh24: connection error")
	ErrTimeout         = errors.New("noosh24: request timed out")
)

const (
	CodeValidationError        = "validation_error"
	CodeNoAPIKey               = "no_api_key"
	CodeInvalidAPIKey          = "invalid_api_key"
	CodeInsufficientScope      = "insufficient_scope"
	CodeModuleNotEnabled       = "module_not_enabled"
	CodeVenueSuspended         = "venue_suspended"
	CodeNotYourReservation     = "not_your_reservation"
	CodeNotFound               = "not_found"
	CodeTableNotFound          = "table_not_found"
	CodeTableTaken             = "table_taken"
	CodeCannotCancel           = "cannot_cancel"
	CodeOutsideHours           = "outside_hours"
	CodeInThePast              = "in_the_past"
	CodeTableTooSmall          = "table_too_small"
	CodeRateLimitExceeded      = "rate_limit_exceeded"
	CodeTemporarilyUnavailable = "temporarily_unavailable"
)

type ErrorKind string

const (
	KindAPI                    ErrorKind = "APIError"
	KindValidation             ErrorKind = "ValidationError"
	KindAuthentication         ErrorKind = "AuthenticationError"
	KindNoAPIKey               ErrorKind = "NoApiKeyError"
	KindInvalidAPIKey          ErrorKind = "InvalidApiKeyError"
	KindPermissionDenied       ErrorKind = "PermissionDeniedError"
	KindInsufficientScope      ErrorKind = "InsufficientScopeError"
	KindModuleNotEnabled       ErrorKind = "ModuleNotEnabledError"
	KindVenueSuspended         ErrorKind = "VenueSuspendedError"
	KindNotYourReservation     ErrorKind = "NotYourReservationError"
	KindNotFound               ErrorKind = "NotFoundError"
	KindTableNotFound          ErrorKind = "TableNotFoundError"
	KindConflict               ErrorKind = "ConflictError"
	KindTableTaken             ErrorKind = "TableTakenError"
	KindCannotCancel           ErrorKind = "CannotCancelError"
	KindUnprocessable          ErrorKind = "UnprocessableError"
	KindOutsideHours           ErrorKind = "OutsideHoursError"
	KindInThePast              ErrorKind = "InThePastError"
	KindTableTooSmall          ErrorKind = "TableTooSmallError"
	KindRateLimit              ErrorKind = "RateLimitError"
	KindServer                 ErrorKind = "ServerError"
	KindTemporarilyUnavailable ErrorKind = "TemporarilyUnavailableError"
)

var kindParents = map[ErrorKind]ErrorKind{
	KindNoAPIKey:               KindAuthentication,
	KindInvalidAPIKey:          KindAuthentication,
	KindInsufficientScope:      KindPermissionDenied,
	KindModuleNotEnabled:       KindPermissionDenied,
	KindVenueSuspended:         KindPermissionDenied,
	KindNotYourReservation:     KindPermissionDenied,
	KindTableNotFound:          KindNotFound,
	KindTableTaken:             KindConflict,
	KindCannotCancel:           KindConflict,
	KindOutsideHours:           KindUnprocessable,
	KindInThePast:              KindUnprocessable,
	KindTableTooSmall:          KindUnprocessable,
	KindTemporarilyUnavailable: KindServer,
}

var kindByCode = map[string]ErrorKind{
	CodeValidationError:        KindValidation,
	CodeNoAPIKey:               KindNoAPIKey,
	CodeInvalidAPIKey:          KindInvalidAPIKey,
	CodeInsufficientScope:      KindInsufficientScope,
	CodeModuleNotEnabled:       KindModuleNotEnabled,
	CodeVenueSuspended:         KindVenueSuspended,
	CodeNotYourReservation:     KindNotYourReservation,
	CodeNotFound:               KindNotFound,
	CodeTableNotFound:          KindTableNotFound,
	CodeTableTaken:             KindTableTaken,
	CodeCannotCancel:           KindCannotCancel,
	CodeOutsideHours:           KindOutsideHours,
	CodeInThePast:              KindInThePast,
	CodeTableTooSmall:          KindTableTooSmall,
	CodeRateLimitExceeded:      KindRateLimit,
	CodeTemporarilyUnavailable: KindTemporarilyUnavailable,
}

var kindByStatus = map[int]ErrorKind{
	400: KindValidation,
	401: KindAuthentication,
	403: KindPermissionDenied,
	404: KindNotFound,
	409: KindConflict,
	422: KindUnprocessable,
	429: KindRateLimit,
}

func (k ErrorKind) String() string {
	return string(k)
}

func (k ErrorKind) Parent() ErrorKind {
	if k == KindAPI || k == "" {
		return ""
	}
	if p, ok := kindParents[k]; ok {
		return p
	}
	return KindAPI
}

func (k ErrorKind) Is(target ErrorKind) bool {
	for cur := k; cur != ""; cur = cur.Parent() {
		if cur == target {
			return true
		}
	}
	return false
}

type APIError struct {
	Status  int
	Code    string
	Message string
	Kind    ErrorKind
	Header  http.Header
	Body    string
}

func (e *APIError) Error() string {
	if e.Code != "" {
		return fmt.Sprintf("noosh24: %s (HTTP %d %s)", e.Message, e.Status, e.Code)
	}
	return fmt.Sprintf("noosh24: %s (HTTP %d)", e.Message, e.Status)
}

func (e *APIError) RetryAfter() (time.Duration, bool) {
	if e == nil || e.Header == nil {
		return 0, false
	}
	seconds, ok := retryAfterSeconds(e.Header.Get("Retry-After"))
	if !ok {
		return 0, false
	}
	return time.Duration(math.Trunc(seconds)) * time.Second, true
}

func retryAfterSeconds(value string) (float64, bool) {
	value = strings.TrimSpace(value)
	if value == "" {
		return 0, false
	}
	seconds, err := strconv.ParseFloat(value, 64)
	if err != nil || math.IsNaN(seconds) || math.IsInf(seconds, 0) {
		return 0, false
	}
	return max(0, seconds), true
}

func newAPIError(status int, header http.Header, body []byte) *APIError {
	var code, message string
	var parsed map[string]any
	if json.Unmarshal(body, &parsed) == nil {
		if s, ok := parsed["error"].(string); ok {
			code = s
		}
		if s, ok := parsed["message"].(string); ok {
			message = s
		}
	}
	if message == "" {
		message = code
	}
	if message == "" {
		message = "HTTP " + strconv.Itoa(status)
	}
	return &APIError{Status: status, Code: code, Message: message, Kind: kindFor(status, code), Header: header, Body: string(body)}
}

func kindFor(status int, code string) ErrorKind {
	if k, ok := kindByCode[code]; ok {
		return k
	}
	if k, ok := kindByStatus[status]; ok {
		return k
	}
	if status >= 500 {
		return KindServer
	}
	return KindAPI
}

type ConnectionError struct {
	Timeout bool
	Err     error
}

func (e *ConnectionError) Error() string {
	if e.Timeout {
		return "noosh24: request timed out: " + e.Err.Error()
	}
	return "noosh24: could not reach the Noosh24 API: " + e.Err.Error()
}

func (e *ConnectionError) Unwrap() error {
	return e.Err
}

func (e *ConnectionError) Is(target error) bool {
	return target == ErrConnection || (e.Timeout && target == ErrTimeout)
}

func AsAPIError(err error) (*APIError, bool) {
	var apiErr *APIError
	if errors.As(err, &apiErr) {
		return apiErr, true
	}
	return nil, false
}

func IsKind(err error, kind ErrorKind) bool {
	apiErr, ok := AsAPIError(err)
	return ok && apiErr.Kind.Is(kind)
}

func IsValidation(err error) bool             { return IsKind(err, KindValidation) }
func IsAuthentication(err error) bool         { return IsKind(err, KindAuthentication) }
func IsNoAPIKey(err error) bool               { return IsKind(err, KindNoAPIKey) }
func IsInvalidAPIKey(err error) bool          { return IsKind(err, KindInvalidAPIKey) }
func IsPermissionDenied(err error) bool       { return IsKind(err, KindPermissionDenied) }
func IsInsufficientScope(err error) bool      { return IsKind(err, KindInsufficientScope) }
func IsModuleNotEnabled(err error) bool       { return IsKind(err, KindModuleNotEnabled) }
func IsVenueSuspended(err error) bool         { return IsKind(err, KindVenueSuspended) }
func IsNotYourReservation(err error) bool     { return IsKind(err, KindNotYourReservation) }
func IsNotFound(err error) bool               { return IsKind(err, KindNotFound) }
func IsTableNotFound(err error) bool          { return IsKind(err, KindTableNotFound) }
func IsConflict(err error) bool               { return IsKind(err, KindConflict) }
func IsTableTaken(err error) bool             { return IsKind(err, KindTableTaken) }
func IsCannotCancel(err error) bool           { return IsKind(err, KindCannotCancel) }
func IsUnprocessable(err error) bool          { return IsKind(err, KindUnprocessable) }
func IsOutsideHours(err error) bool           { return IsKind(err, KindOutsideHours) }
func IsInThePast(err error) bool              { return IsKind(err, KindInThePast) }
func IsTableTooSmall(err error) bool          { return IsKind(err, KindTableTooSmall) }
func IsRateLimited(err error) bool            { return IsKind(err, KindRateLimit) }
func IsServerError(err error) bool            { return IsKind(err, KindServer) }
func IsTemporarilyUnavailable(err error) bool { return IsKind(err, KindTemporarilyUnavailable) }
