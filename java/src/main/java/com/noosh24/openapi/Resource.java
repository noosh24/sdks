package com.noosh24.openapi;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Function;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

abstract class Resource {
    final Noosh24Client client;

    Resource(Noosh24Client client) {
        this.client = client;
    }

    static String id(@Nullable String value) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("An id is required");
        }
        return Query.escape(value);
    }

    <T> Page<T> page(String path, Function<JsonNode, T> factory, Query query) {
        JsonNode data = client.request("GET", path, query, null, true).data();
        List<T> items = items(data, factory);
        int total = intField(data, "total", items.size());
        int limit = intField(data, "limit", firstInt(query, "limit", items.size()));
        int offset = intField(data, "offset", firstInt(query, "offset", 0));
        return new Page<>(items, total, limit, offset);
    }

    <T> PagedIterable<T> paginate(String path, Function<JsonNode, T> factory, Query query, int pageSize) {
        Query base = query.copy();
        if (!base.has("limit")) {
            base.set("limit", pageSize);
        }
        int start = firstInt(base, "offset", 0);
        return new PagedIterable<>(offset -> page(path, factory, base.copy().set("offset", offset)), start);
    }

    <T> List<T> all(String path, Function<JsonNode, T> factory) {
        return items(client.request("GET", path, null, null, true).data(), factory);
    }

    <T> T one(String path, Function<JsonNode, T> factory, @Nullable Query query) {
        return factory.apply(client.request("GET", path, query, null, true).data());
    }

    private static <T> List<T> items(@Nullable JsonNode data, Function<JsonNode, T> factory) {
        List<T> out = new ArrayList<>();
        JsonNode items = data == null ? null : data.get("items");
        if (items != null && items.isArray()) {
            for (JsonNode item : items) {
                if (item.isObject()) {
                    out.add(factory.apply(item));
                }
            }
        }
        return out;
    }

    private static int intField(@Nullable JsonNode data, String key, int fallback) {
        JsonNode v = data == null ? null : data.get(key);
        return v != null && v.isNumber() ? v.numberValue().intValue() : fallback;
    }

    private static int firstInt(Query query, String key, int fallback) {
        List<String> values = query.get(key);
        if (values.isEmpty()) {
            return fallback;
        }
        try {
            return Integer.parseInt(values.get(0));
        } catch (NumberFormatException e) {
            return fallback;
        }
    }
}
