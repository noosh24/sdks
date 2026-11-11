from __future__ import annotations

import httpx
import pytest

import noosh24
from noosh24 import APIConnectionError, APIError, APITimeoutError, RateLimitError, TemporarilyUnavailableError
from noosh24._client import _query_pairs


def test_sends_key_and_headers_to_default_base_url(client, http):
    http.json(
        200,
        {
            "data": {
                "restaurant": {"id": "r1", "name": "Masago", "slug": "masago"},
                "key": {"id": "k1", "name": "Wolt", "prefix": "nsk_Ab3dE9xQ", "scopes": ["menu:read", "orders:read"]},
                "subscription": {"status": "active", "modules": ["loyalty"]},
                "features": {"loyalty": True, "inventory": False},
            }
        },
    )

    me = client.whoami()

    request = http.last
    assert request.method == "GET"
    assert str(request.url) == "https://open-api.noosh24.com/v1/whoami"
    assert request.headers["authorization"] == "Bearer nsk_test_123"
    assert request.headers["accept"] == "application/json"
    assert request.headers["user-agent"] == "noosh24-python/" + noosh24.__version__
    assert request.content == b""
    assert me.restaurant.name == "Masago"
    assert me.key.scopes == ["menu:read", "orders:read"]
    assert me.subscription.status == "active"
    assert me.features.loyalty is True
    assert me.features.inventory is False


def test_custom_base_url_and_user_agent(make_client, http):
    client = make_client(base_url="http://localhost:8080/v1/", user_agent="acme-pos/2.1")
    http.json(200, {"data": {}})

    client.whoami()

    assert str(http.last.url) == "http://localhost:8080/v1/whoami"
    assert http.last.headers["user-agent"] == "acme-pos/2.1 noosh24-python/" + noosh24.__version__


def test_rejects_empty_key():
    with pytest.raises(ValueError):
        noosh24.Noosh24("  ")


def test_context_manager_closes_own_client():
    with noosh24.Noosh24("nsk_x") as client:
        assert client.menu is not None
    assert client._http.is_closed


def test_retries_rate_limit_after_retry_after(client, http, sleeps):
    http.json(429, {"error": "rate_limit_exceeded", "message": "slow down"}, {"Retry-After": "3"})
    http.json(200, {"data": {"items": [], "total": 0}})

    assert client.tables.list() == []
    assert len(http.requests) == 2
    assert sleeps == [3.0]


def test_gives_up_after_max_retries(make_client, http):
    client = make_client(max_retries=1)
    http.json(429, {"error": "rate_limit_exceeded", "message": "slow down"}, {"Retry-After": "1"})
    http.json(429, {"error": "rate_limit_exceeded", "message": "slow down"}, {"Retry-After": "7"})

    with pytest.raises(RateLimitError) as info:
        client.tables.list()

    assert info.value.status == 429
    assert info.value.code == "rate_limit_exceeded"
    assert info.value.retry_after == 7
    assert str(info.value) == "slow down"
    assert len(http.requests) == 2


def test_does_not_wait_longer_than_a_minute(client, http, sleeps):
    http.json(429, {"error": "rate_limit_exceeded"}, {"Retry-After": "120"})

    with pytest.raises(RateLimitError):
        client.tables.list()
    assert len(http.requests) == 1
    assert sleeps == []


def test_backs_off_on_temporarily_unavailable(client, http, sleeps):
    for _ in range(3):
        http.json(503, {"error": "temporarily_unavailable", "message": "try again"})

    with pytest.raises(TemporarilyUnavailableError):
        client.tables.list_halls()
    assert len(http.requests) == 3
    assert sleeps == [0.5, 1.0]


def test_retries_connection_errors_on_reads(make_client, http):
    client = make_client(max_retries=1)
    http.fail(httpx.ConnectError("connection reset"))
    http.json(200, {"data": {"items": [{"id": "h1", "name": "Main", "position": 1}], "total": 1}})

    assert client.tables.list_halls()[0].name == "Main"

    http.fail(httpx.ConnectError("connection reset")).fail(httpx.ConnectError("connection reset"))
    with pytest.raises(APIConnectionError, match="connection reset"):
        client.tables.list_halls()


def test_timeout(make_client, http):
    client = make_client(max_retries=0)
    http.fail(httpx.ReadTimeout("read timed out"))

    with pytest.raises(APITimeoutError):
        client.whoami()


def test_body_that_is_not_json_is_an_api_error(client, http):
    http.raw(200, "<html>gateway</html>")

    with pytest.raises(APIError):
        client.whoami()


def test_builds_repeated_query_parameters():
    assert _query_pairs({"sort": ["price desc", "name asc"], "where": "a = 1", "skip": None, "available": True}) == [
        ("sort", "price desc"),
        ("sort", "name asc"),
        ("where", "a = 1"),
        ("available", "true"),
    ]
