package com.noosh24.openapi;

import java.io.IOException;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import tools.jackson.databind.JsonNode;

final class MockTransport implements HttpTransport {
    final Deque<Object> queue = new ArrayDeque<>();
    final List<Request> requests = new ArrayList<>();
    final List<Duration> sleeps = new ArrayList<>();
    boolean closed;

    MockTransport json(int status, String body) {
        return json(status, body, Map.of());
    }

    MockTransport json(int status, String body, Map<String, String> headers) {
        Map<String, List<String>> h = new LinkedHashMap<>();
        h.put("Content-Type", List.of("application/json"));
        headers.forEach((k, v) -> h.put(k, List.of(v)));
        queue.add(new Response(status, h, body.getBytes(StandardCharsets.UTF_8)));
        return this;
    }

    MockTransport raw(int status, String body) {
        queue.add(new Response(status, Map.of(), body.getBytes(StandardCharsets.UTF_8)));
        return this;
    }

    MockTransport fail(IOException error) {
        queue.add(error);
        return this;
    }

    @Override
    public Response send(Request request) throws IOException {
        requests.add(request);
        Object next = queue.poll();
        if (next == null) {
            throw new AssertionError("No response queued for " + request.method() + " " + request.uri());
        }
        if (next instanceof IOException e) {
            throw e;
        }
        return (Response) next;
    }

    @Override
    public void close() {
        closed = true;
    }

    Noosh24Client client() {
        return builder().build();
    }

    Noosh24Client.Builder builder() {
        return Noosh24Client.builder().apiKey("nsk_test_123").transport(this).sleeper(sleeps::add);
    }

    Request last() {
        return requests.get(requests.size() - 1);
    }

    static Map<String, List<String>> query(Request request) {
        Map<String, List<String>> out = new LinkedHashMap<>();
        String raw = request.uri().getRawQuery();
        if (raw == null || raw.isEmpty()) {
            return out;
        }
        for (String pair : raw.split("&")) {
            int eq = pair.indexOf('=');
            String name = URLDecoder.decode(pair.substring(0, eq), StandardCharsets.UTF_8);
            String value = URLDecoder.decode(pair.substring(eq + 1), StandardCharsets.UTF_8);
            out.computeIfAbsent(name, k -> new ArrayList<>()).add(value);
        }
        return out;
    }

    static JsonNode body(Request request) {
        return JsonSupport.MAPPER.readTree(request.bodyAsString());
    }

    static String page(String items, int total, int limit, int offset) {
        return "{\"data\":{\"items\":" + items + ",\"total\":" + total + ",\"limit\":" + limit + ",\"offset\":" + offset + "}}";
    }

    static String page(String items, int total) {
        return page(items, total, 20, 0);
    }
}
