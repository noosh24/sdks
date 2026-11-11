from __future__ import annotations

import json
import time
from typing import Any, List, Mapping, Optional, Sequence, Tuple, Union

import httpx

from ._resources import Customers, Loyalty, Menu, Orders, Payments, Reservations, Reviews, Stock, Tables
from ._version import __version__
from .errors import APIConnectionError, APIError, APITimeoutError, error_from_response
from .models import Whoami

__all__ = ["Noosh24", "DEFAULT_BASE_URL"]

DEFAULT_BASE_URL = "https://open-api.noosh24.com/v1"

_RETRY_STATUSES = frozenset({429, 502, 503, 504})
_MAX_RETRY_WAIT = 60.0

QueryValue = Union[str, int, float, bool, None, Sequence[Union[str, int, float, bool]]]


class Noosh24:
    def __init__(
        self,
        api_key: str,
        *,
        base_url: Optional[str] = None,
        timeout: float = 30.0,
        max_retries: int = 2,
        user_agent: Optional[str] = None,
        http_client: Optional[httpx.Client] = None,
    ) -> None:
        key = (api_key or "").strip()
        if not key:
            raise ValueError("An API key is required")
        self._api_key = key
        self._base_url = (base_url or DEFAULT_BASE_URL).rstrip("/")
        self._timeout = timeout
        self._max_retries = max(0, int(max_retries))
        agent = "noosh24-python/%s" % __version__
        self._user_agent = "%s %s" % (user_agent, agent) if user_agent else agent
        self._owns_http = http_client is None
        self._http = http_client if http_client is not None else httpx.Client(timeout=timeout, follow_redirects=False)

        self.menu = Menu(self)
        self.reservations = Reservations(self)
        self.orders = Orders(self)
        self.payments = Payments(self)
        self.tables = Tables(self)
        self.customers = Customers(self)
        self.loyalty = Loyalty(self)
        self.stock = Stock(self)
        self.reviews = Reviews(self)

    def whoami(self) -> Whoami:
        _, data = self.request("GET", "/whoami")
        return Whoami.from_dict(data if isinstance(data, Mapping) else {})

    def close(self) -> None:
        if self._owns_http:
            self._http.close()

    def __enter__(self) -> "Noosh24":
        return self

    def __exit__(self, *exc: Any) -> None:
        self.close()

    def request(
        self,
        method: str,
        path: str,
        *,
        query: Optional[Mapping[str, QueryValue]] = None,
        body: Any = None,
        retryable: bool = True,
    ) -> Tuple[int, Any]:
        url = self._base_url + path
        params = _query_pairs(query or {})
        headers = {
            "Authorization": "Bearer " + self._api_key,
            "Accept": "application/json",
            "User-Agent": self._user_agent,
        }
        content: Optional[bytes] = None
        if body is not None:
            headers["Content-Type"] = "application/json"
            content = json.dumps(body, ensure_ascii=False, separators=(",", ":")).encode("utf-8")

        attempt = 0
        while True:
            try:
                response = self._http.request(
                    method, url, params=params, headers=headers, content=content, timeout=self._timeout
                )
            except httpx.TimeoutException as exc:
                if retryable and attempt < self._max_retries:
                    time.sleep(_backoff(attempt))
                    attempt += 1
                    continue
                raise APITimeoutError("Request timed out after %s s" % self._timeout) from exc
            except httpx.TransportError as exc:
                if retryable and attempt < self._max_retries:
                    time.sleep(_backoff(attempt))
                    attempt += 1
                    continue
                raise APIConnectionError("Could not reach the Noosh24 API: %s" % exc) from exc

            if 200 <= response.status_code < 300:
                return response.status_code, _decode(response)
            wait = _retry_wait(response, attempt)
            if retryable and attempt < self._max_retries and wait is not None:
                time.sleep(wait)
                attempt += 1
                continue
            raise error_from_response(response.status_code, dict(response.headers), response.text)


def _query_pairs(query: Mapping[str, QueryValue]) -> List[Tuple[str, str]]:
    pairs: List[Tuple[str, str]] = []
    for name, value in query.items():
        if value is None:
            continue
        values = value if isinstance(value, (list, tuple)) else [value]
        for item in values:
            if item is None:
                continue
            if isinstance(item, bool):
                item = "true" if item else "false"
            pairs.append((name, str(item)))
    return pairs


def _decode(response: httpx.Response) -> Any:
    if not response.content:
        return None
    try:
        parsed = response.json()
    except ValueError:
        raise APIError(
            response.status_code, None, "The API answered with a body that is not JSON", dict(response.headers), response.text
        ) from None
    if not isinstance(parsed, dict) or "data" not in parsed:
        raise APIError(
            response.status_code, None, 'The API answered without a "data" field', dict(response.headers), response.text
        )
    return parsed["data"]


def _retry_wait(response: httpx.Response, attempt: int) -> Optional[float]:
    if response.status_code not in _RETRY_STATUSES:
        return None
    header = response.headers.get("retry-after")
    if header is not None:
        try:
            wait = max(0.0, float(header))
        except ValueError:
            return _backoff(attempt)
        return wait if wait <= _MAX_RETRY_WAIT else None
    return _backoff(attempt)


def _backoff(attempt: int) -> float:
    return min(8.0, 0.5 * (2 ** attempt))
