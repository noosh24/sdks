from __future__ import annotations

import pytest

import noosh24 as n

CASES = [
    (400, "validation_error", n.ValidationError, n.APIError),
    (401, "no_api_key", n.NoApiKeyError, n.AuthenticationError),
    (401, "invalid_api_key", n.InvalidApiKeyError, n.AuthenticationError),
    (403, "insufficient_scope", n.InsufficientScopeError, n.PermissionDeniedError),
    (403, "module_not_enabled", n.ModuleNotEnabledError, n.PermissionDeniedError),
    (403, "venue_suspended", n.VenueSuspendedError, n.PermissionDeniedError),
    (403, "not_your_reservation", n.NotYourReservationError, n.PermissionDeniedError),
    (404, "not_found", n.NotFoundError, n.APIError),
    (404, "table_not_found", n.TableNotFoundError, n.NotFoundError),
    (409, "table_taken", n.TableTakenError, n.ConflictError),
    (409, "cannot_cancel", n.CannotCancelError, n.ConflictError),
    (422, "outside_hours", n.OutsideHoursError, n.UnprocessableError),
    (422, "in_the_past", n.InThePastError, n.UnprocessableError),
    (422, "table_too_small", n.TableTooSmallError, n.UnprocessableError),
    (429, "rate_limit_exceeded", n.RateLimitError, n.APIError),
    (503, "temporarily_unavailable", n.TemporarilyUnavailableError, n.ServerError),
    (403, "something_new", n.PermissionDeniedError, n.APIError),
    (409, "something_new", n.ConflictError, n.APIError),
    (500, "query_failed", n.ServerError, n.APIError),
    (418, None, n.APIError, n.Noosh24Error),
]


@pytest.mark.parametrize("status,code,cls,parent", CASES)
def test_maps_error_codes(make_client, http, status, code, cls, parent):
    client = make_client(max_retries=0)
    http.json(status, {"nope": True} if code is None else {"error": code, "message": "Mesaj"})

    with pytest.raises(n.APIError) as info:
        client.customers.get("c1")

    error = info.value
    assert type(error) is cls
    assert isinstance(error, parent)
    assert isinstance(error, n.Noosh24Error)
    assert error.status == status
    assert error.code == code
    assert error.message == (f"HTTP {status}" if code is None else "Mesaj")


def test_validation_error_is_not_retried(client, http):
    http.json(400, {"error": "validation_error", "message": '"nope" is not a filterable field on this resource'})

    with pytest.raises(n.ValidationError, match="not a filterable field"):
        client.menu.list_products(where="nope = 1")
    assert len(http.requests) == 1
