from __future__ import annotations

import json
from typing import Any, Dict, List, Optional, Union
from urllib.parse import parse_qs, urlsplit

import httpx
import pytest

import noosh24
from noosh24 import _client


class MockHTTP:
    def __init__(self) -> None:
        self.queue: List[Union[httpx.Response, Exception]] = []
        self.requests: List[httpx.Request] = []

    def json(self, status: int, body: Any, headers: Optional[Dict[str, str]] = None) -> "MockHTTP":
        self.queue.append(httpx.Response(status, json=body, headers=headers or {}))
        return self

    def raw(self, status: int, text: str) -> "MockHTTP":
        self.queue.append(httpx.Response(status, text=text))
        return self

    def fail(self, error: Exception) -> "MockHTTP":
        self.queue.append(error)
        return self

    def handler(self, request: httpx.Request) -> httpx.Response:
        self.requests.append(request)
        if not self.queue:
            raise AssertionError("No response queued for %s %s" % (request.method, request.url))
        nxt = self.queue.pop(0)
        if isinstance(nxt, Exception):
            raise nxt
        return nxt

    @property
    def last(self) -> httpx.Request:
        return self.requests[-1]


def query(request: httpx.Request) -> Dict[str, List[str]]:
    return parse_qs(urlsplit(str(request.url)).query, keep_blank_values=True)


def body(request: httpx.Request) -> Any:
    return json.loads(request.content.decode("utf-8"))


def page(items: List[Dict[str, Any]], total: int, limit: int = 20, offset: int = 0) -> Dict[str, Any]:
    return {"data": {"items": items, "total": total, "limit": limit, "offset": offset}}


@pytest.fixture
def sleeps(monkeypatch: pytest.MonkeyPatch) -> List[float]:
    calls: List[float] = []
    monkeypatch.setattr(_client.time, "sleep", calls.append)
    return calls


@pytest.fixture
def http() -> MockHTTP:
    return MockHTTP()


@pytest.fixture
def make_client(http: MockHTTP, sleeps: List[float]):
    def make(**options: Any) -> noosh24.Noosh24:
        return noosh24.Noosh24("nsk_test_123", http_client=httpx.Client(transport=httpx.MockTransport(http.handler)), **options)

    return make


@pytest.fixture
def client(make_client) -> noosh24.Noosh24:
    return make_client()
