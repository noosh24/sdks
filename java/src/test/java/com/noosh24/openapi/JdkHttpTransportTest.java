package com.noosh24.openapi;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.noosh24.openapi.model.CreateReservationResult;
import com.noosh24.openapi.model.NewReservation;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class JdkHttpTransportTest {
    private HttpServer server;
    private ExecutorService executor;
    private final Map<String, String> seen = new ConcurrentHashMap<>();
    private final List<Duration> sleeps = new ArrayList<>();

    @BeforeEach
    void start() throws IOException {
        server = HttpServer.create(new InetSocketAddress(InetAddress.getLoopbackAddress(), 0), 0);
        server.createContext("/v1/reservations", exchange -> {
            seen.put("method", exchange.getRequestMethod());
            seen.put("authorization", exchange.getRequestHeaders().getFirst("Authorization"));
            seen.put("user-agent", exchange.getRequestHeaders().getFirst("User-Agent"));
            seen.put("content-type", exchange.getRequestHeaders().getFirst("Content-Type"));
            seen.put("body", new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
            byte[] out = "{\"data\": {\"id\": \"r1\", \"code\": \"K7Q2\", \"status\": \"pending\"}}".getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(201, out.length);
            exchange.getResponseBody().write(out);
            exchange.close();
        });
        server.createContext("/v1/whoami", exchange -> {
            try {
                Thread.sleep(2000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            exchange.sendResponseHeaders(200, -1);
            exchange.close();
        });
        executor = Executors.newCachedThreadPool();
        server.setExecutor(executor);
        server.start();
    }

    @AfterEach
    void stop() {
        server.stop(0);
        executor.shutdownNow();
    }

    private Noosh24Client.Builder builder() {
        return Noosh24Client.builder()
                .apiKey("nsk_test_123")
                .baseUrl("http://127.0.0.1:" + server.getAddress().getPort() + "/v1")
                .sleeper(sleeps::add);
    }

    @Test
    void sendsARealRequestThroughTheJdkClient() {
        try (Noosh24Client client = builder().userAgent("acme/1").build()) {
            CreateReservationResult result = client.reservations().create(NewReservation.builder()
                    .date("2026-11-20").time("19:30").guests(2).guestName("Aysel Məmmədova").phone("+994501234567")
                    .externalRef("acme-1").build());

            assertEquals(true, result.created());
            assertEquals("K7Q2", result.reservation().code());
        }
        assertEquals("POST", seen.get("method"));
        assertEquals("Bearer nsk_test_123", seen.get("authorization"));
        assertEquals("acme/1 noosh24-java/" + Noosh24Client.VERSION, seen.get("user-agent"));
        assertEquals("application/json", seen.get("content-type"));
        assertEquals("{\"date\":\"2026-11-20\",\"time\":\"19:30\",\"guests\":2,\"guestName\":\"Aysel Məmmədova\","
                + "\"phone\":\"+994501234567\",\"externalRef\":\"acme-1\"}", seen.get("body"));
    }

    @Test
    void aSlowServerIsATimeout() {
        try (Noosh24Client client = builder().timeout(Duration.ofMillis(200)).maxRetries(1).build()) {
            assertThrows(ApiTimeoutException.class, client::whoami);
        }
        assertEquals(List.of(Duration.ofMillis(500)), sleeps);
    }

    @Test
    void aClosedPortIsAConnectionError() {
        int port;
        try (ServerSocket socket = new ServerSocket(0, 1, InetAddress.getLoopbackAddress())) {
            port = socket.getLocalPort();
        } catch (IOException e) {
            throw new AssertionError(e);
        }
        try (Noosh24Client client = builder().baseUrl("http://127.0.0.1:" + port + "/v1").maxRetries(0).build()) {
            ApiConnectionException error = assertThrows(ApiConnectionException.class, client::whoami);
            assertEquals(ApiConnectionException.class, error.getClass());
        }
    }
}
