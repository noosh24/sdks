package com.noosh24.openapi;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.noosh24.openapi.model.Whoami;
import java.net.ConnectException;
import java.net.http.HttpTimeoutException;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.OptionalInt;
import org.junit.jupiter.api.Test;

class ClientTest {
    private final MockTransport http = new MockTransport();

    @Test
    void sendsKeyAndHeadersToDefaultBaseUrl() {
        http.json(200, """
                {"data": {
                  "restaurant": {"id": "r1", "name": "Masago", "slug": "masago"},
                  "key": {"id": "k1", "name": "Wolt", "prefix": "nsk_Ab3dE9xQ", "scopes": ["menu:read", "orders:read"]},
                  "subscription": {"status": "active", "modules": ["loyalty"]},
                  "features": {"loyalty": true, "inventory": false}
                }}""");

        Whoami me = http.client().whoami();

        HttpTransport.Request request = http.last();
        assertEquals("GET", request.method());
        assertEquals("https://open-api.noosh24.com/v1/whoami", request.uri().toString());
        assertEquals("Bearer nsk_test_123", request.headers().get("Authorization"));
        assertEquals("application/json", request.headers().get("Accept"));
        assertEquals("noosh24-java/" + Noosh24Client.VERSION, request.headers().get("User-Agent"));
        assertNull(request.body());
        assertFalse(request.headers().containsKey("Content-Type"));
        assertEquals(Duration.ofSeconds(30), request.timeout());
        assertEquals("Masago", me.restaurant().name());
        assertEquals(List.of("menu:read", "orders:read"), me.key().scopes());
        assertEquals("active", me.subscription().status());
        assertEquals(Boolean.TRUE, me.features().loyalty());
        assertEquals(Boolean.FALSE, me.features().inventory());
    }

    @Test
    void customBaseUrlUserAgentAndTimeout() {
        Noosh24Client client = http.builder()
                .baseUrl("http://localhost:8080/v1/")
                .userAgent("acme-pos/2.1")
                .timeout(Duration.ofSeconds(5))
                .build();
        http.json(200, "{\"data\": {}}");

        client.whoami();

        assertEquals("http://localhost:8080/v1/whoami", http.last().uri().toString());
        assertEquals("acme-pos/2.1 noosh24-java/" + Noosh24Client.VERSION, http.last().headers().get("User-Agent"));
        assertEquals(Duration.ofSeconds(5), http.last().timeout());
    }

    @Test
    void rejectsEmptyKey() {
        assertThrows(IllegalArgumentException.class, () -> new Noosh24Client("  "));
        assertThrows(IllegalArgumentException.class, () -> new Noosh24Client(""));
        assertThrows(IllegalArgumentException.class, () -> Noosh24Client.builder().build());
    }

    @Test
    void closeLeavesAnInjectedTransportOpen() {
        try (Noosh24Client client = http.client()) {
            assertTrue(client.menu() != null);
        }
        assertFalse(http.closed);
        try (Noosh24Client own = new Noosh24Client("nsk_x")) {
            assertEquals(Noosh24Client.DEFAULT_BASE_URL, own.baseUrl());
        }
    }

    @Test
    void retriesRateLimitAfterRetryAfter() {
        http.json(429, "{\"error\": \"rate_limit_exceeded\", \"message\": \"slow down\"}", Map.of("Retry-After", "3"));
        http.json(200, "{\"data\": {\"items\": [], \"total\": 0}}");

        assertEquals(List.of(), http.client().tables().list());
        assertEquals(2, http.requests.size());
        assertEquals(List.of(Duration.ofSeconds(3)), http.sleeps);
    }

    @Test
    void givesUpAfterMaxRetries() {
        Noosh24Client client = http.builder().maxRetries(1).build();
        http.json(429, "{\"error\": \"rate_limit_exceeded\", \"message\": \"slow down\"}", Map.of("Retry-After", "1"));
        http.json(429, "{\"error\": \"rate_limit_exceeded\", \"message\": \"slow down\"}", Map.of("Retry-After", "7"));

        RateLimitException error = assertThrows(RateLimitException.class, () -> client.tables().list());

        assertEquals(429, error.getStatus());
        assertEquals("rate_limit_exceeded", error.getCode());
        assertEquals(OptionalInt.of(7), error.getRetryAfter());
        assertEquals("slow down", error.getMessage());
        assertEquals("7", error.getHeaders().get("retry-after"));
        assertEquals(2, http.requests.size());
    }

    @Test
    void retryAfterIsEmptyWithoutTheHeader() {
        http.json(429, "{\"error\": \"rate_limit_exceeded\"}");
        RateLimitException error = assertThrows(RateLimitException.class, () -> http.builder().maxRetries(0).build().whoami());
        assertEquals(OptionalInt.empty(), error.getRetryAfter());
        assertEquals("rate_limit_exceeded", error.getMessage());
    }

    @Test
    void doesNotWaitLongerThanAMinute() {
        http.json(429, "{\"error\": \"rate_limit_exceeded\"}", Map.of("Retry-After", "120"));

        assertThrows(RateLimitException.class, () -> http.client().tables().list());
        assertEquals(1, http.requests.size());
        assertEquals(List.of(), http.sleeps);
    }

    @Test
    void backsOffOnTemporarilyUnavailable() {
        for (int i = 0; i < 3; i++) {
            http.json(503, "{\"error\": \"temporarily_unavailable\", \"message\": \"try again\"}");
        }

        assertThrows(TemporarilyUnavailableException.class, () -> http.client().tables().listHalls());
        assertEquals(3, http.requests.size());
        assertEquals(List.of(Duration.ofMillis(500), Duration.ofSeconds(1)), http.sleeps);
    }

    @Test
    void backoffGrowsAndIsCapped() {
        assertEquals(Duration.ofMillis(500), Noosh24Client.backoff(0));
        assertEquals(Duration.ofSeconds(2), Noosh24Client.backoff(2));
        assertEquals(Duration.ofSeconds(8), Noosh24Client.backoff(10));
    }

    @Test
    void retriesConnectionErrorsOnReads() {
        Noosh24Client client = http.builder().maxRetries(1).build();
        http.fail(new ConnectException("connection reset"));
        http.json(200, "{\"data\": {\"items\": [{\"id\": \"h1\", \"name\": \"Main\", \"position\": 1}], \"total\": 1}}");

        assertEquals("Main", client.tables().listHalls().get(0).name());

        http.fail(new ConnectException("connection reset")).fail(new ConnectException("connection reset"));
        ApiConnectionException error = assertThrows(ApiConnectionException.class, () -> client.tables().listHalls());
        assertTrue(error.getMessage().contains("connection reset"));
        assertFalse(error instanceof ApiTimeoutException);
        assertTrue(error.getCause() instanceof ConnectException);
    }

    @Test
    void timeout() {
        Noosh24Client client = http.builder().maxRetries(0).build();
        http.fail(new HttpTimeoutException("read timed out"));

        ApiTimeoutException error = assertThrows(ApiTimeoutException.class, client::whoami);
        assertTrue(error instanceof ApiConnectionException);
        assertTrue(error instanceof Noosh24Exception);
    }

    @Test
    void bodyThatIsNotJsonIsAnApiError() {
        http.raw(200, "<html>gateway</html>");

        ApiException error = assertThrows(ApiException.class, () -> http.client().whoami());
        assertEquals(ApiException.class, error.getClass());
        assertEquals(200, error.getStatus());
        assertEquals("<html>gateway</html>", error.getBody());
    }

    @Test
    void successWithoutDataIsAnApiError() {
        http.json(200, "{\"items\": []}");

        assertThrows(ApiException.class, () -> http.client().whoami());
    }

    @Test
    void buildsRepeatedQueryParameters() {
        Query query = new Query()
                .add("sort", List.of("price desc", "name asc"))
                .add("where", "a = 1")
                .add("skip", null)
                .add("available", true);

        assertEquals("sort=price%20desc&sort=name%20asc&where=a%20%3D%201&available=true", query.encode());
    }
}
