package com.noosh24.openapi;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.StringJoiner;
import org.jspecify.annotations.Nullable;

final class Query {
    private final Map<String, List<String>> params = new LinkedHashMap<>();

    Query add(String name, @Nullable Object value) {
        if (value == null) {
            return this;
        }
        if (value instanceof Iterable<?> items) {
            for (Object item : items) {
                add(name, item);
            }
            return this;
        }
        params.computeIfAbsent(name, k -> new ArrayList<>()).add(text(value));
        return this;
    }

    Query set(String name, @Nullable Object value) {
        params.remove(name);
        return add(name, value);
    }

    boolean has(String name) {
        return params.containsKey(name);
    }

    List<String> get(String name) {
        return params.getOrDefault(name, List.of());
    }

    Query copy() {
        Query out = new Query();
        params.forEach((name, values) -> out.params.put(name, new ArrayList<>(values)));
        return out;
    }

    String encode() {
        StringJoiner out = new StringJoiner("&");
        params.forEach((name, values) -> {
            for (String value : values) {
                out.add(escape(name) + "=" + escape(value));
            }
        });
        return out.toString();
    }

    static String escape(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8).replace("+", "%20");
    }

    private static String text(Object value) {
        if (value instanceof Boolean b) {
            return b ? "true" : "false";
        }
        return value.toString();
    }
}
