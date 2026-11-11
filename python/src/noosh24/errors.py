from __future__ import annotations

import json
from typing import Dict, Mapping, Optional, Type

__all__ = [
    "Noosh24Error",
    "APIConnectionError",
    "APITimeoutError",
    "APIError",
    "ValidationError",
    "AuthenticationError",
    "NoApiKeyError",
    "InvalidApiKeyError",
    "PermissionDeniedError",
    "InsufficientScopeError",
    "ModuleNotEnabledError",
    "VenueSuspendedError",
    "NotYourReservationError",
    "NotFoundError",
    "TableNotFoundError",
    "ConflictError",
    "TableTakenError",
    "CannotCancelError",
    "UnprocessableError",
    "OutsideHoursError",
    "InThePastError",
    "TableTooSmallError",
    "RateLimitError",
    "ServerError",
    "TemporarilyUnavailableError",
]


class Noosh24Error(Exception):
    pass


class APIConnectionError(Noosh24Error):
    pass


class APITimeoutError(APIConnectionError):
    pass


class APIError(Noosh24Error):
    def __init__(
        self,
        status: int,
        code: Optional[str],
        message: str,
        headers: Optional[Mapping[str, str]] = None,
        body: str = "",
    ) -> None:
        super().__init__(message)
        self.status = status
        self.code = code
        self.message = message
        self.headers: Dict[str, str] = {k.lower(): v for k, v in (headers or {}).items()}
        self.body = body

    def __repr__(self) -> str:
        return "%s(status=%d, code=%r, message=%r)" % (type(self).__name__, self.status, self.code, self.message)


class ValidationError(APIError):
    pass


class AuthenticationError(APIError):
    pass


class NoApiKeyError(AuthenticationError):
    pass


class InvalidApiKeyError(AuthenticationError):
    pass


class PermissionDeniedError(APIError):
    pass


class InsufficientScopeError(PermissionDeniedError):
    pass


class ModuleNotEnabledError(PermissionDeniedError):
    pass


class VenueSuspendedError(PermissionDeniedError):
    pass


class NotYourReservationError(PermissionDeniedError):
    pass


class NotFoundError(APIError):
    pass


class TableNotFoundError(NotFoundError):
    pass


class ConflictError(APIError):
    pass


class TableTakenError(ConflictError):
    pass


class CannotCancelError(ConflictError):
    pass


class UnprocessableError(APIError):
    pass


class OutsideHoursError(UnprocessableError):
    pass


class InThePastError(UnprocessableError):
    pass


class TableTooSmallError(UnprocessableError):
    pass


class RateLimitError(APIError):
    @property
    def retry_after(self) -> Optional[int]:
        value = self.headers.get("retry-after")
        if value is None:
            return None
        try:
            return max(0, int(float(value)))
        except ValueError:
            return None


class ServerError(APIError):
    pass


class TemporarilyUnavailableError(ServerError):
    pass


_BY_CODE: Dict[str, Type[APIError]] = {
    "validation_error": ValidationError,
    "no_api_key": NoApiKeyError,
    "invalid_api_key": InvalidApiKeyError,
    "insufficient_scope": InsufficientScopeError,
    "module_not_enabled": ModuleNotEnabledError,
    "venue_suspended": VenueSuspendedError,
    "not_your_reservation": NotYourReservationError,
    "not_found": NotFoundError,
    "table_not_found": TableNotFoundError,
    "table_taken": TableTakenError,
    "cannot_cancel": CannotCancelError,
    "outside_hours": OutsideHoursError,
    "in_the_past": InThePastError,
    "table_too_small": TableTooSmallError,
    "rate_limit_exceeded": RateLimitError,
    "temporarily_unavailable": TemporarilyUnavailableError,
}

_BY_STATUS: Dict[int, Type[APIError]] = {
    400: ValidationError,
    401: AuthenticationError,
    403: PermissionDeniedError,
    404: NotFoundError,
    409: ConflictError,
    422: UnprocessableError,
    429: RateLimitError,
}


def error_from_response(status: int, headers: Mapping[str, str], body: str) -> APIError:
    code: Optional[str] = None
    message = ""
    try:
        parsed = json.loads(body)
    except ValueError:
        parsed = None
    if isinstance(parsed, dict):
        if isinstance(parsed.get("error"), str):
            code = parsed["error"]
        if isinstance(parsed.get("message"), str):
            message = parsed["message"]
    if not message:
        message = code or "HTTP %d" % status
    cls = _BY_CODE.get(code or "") or _BY_STATUS.get(status) or (ServerError if status >= 500 else APIError)
    return cls(status, code, message, headers, body)
