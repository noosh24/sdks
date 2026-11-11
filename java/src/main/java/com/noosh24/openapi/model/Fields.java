package com.noosh24.openapi.model;

import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.node.JsonNodeFactory;

final class Fields {
    private static final Pattern FRACTION = Pattern.compile("\\.(\\d+)");

    private Fields() {}

    static JsonNode object(@Nullable JsonNode node) {
        return node != null && node.isObject() ? node : JsonNodeFactory.instance.objectNode();
    }

    static @Nullable String string(JsonNode n, String key) {
        JsonNode v = n.get(key);
        if (v == null || v.isNull() || v.isMissingNode() || v.isContainer()) {
            return null;
        }
        return v.isString() ? v.stringValue() : v.asString();
    }

    static @Nullable Integer integer(JsonNode n, String key) {
        JsonNode v = n.get(key);
        return v != null && v.isNumber() ? v.numberValue().intValue() : null;
    }

    static @Nullable Double number(JsonNode n, String key) {
        JsonNode v = n.get(key);
        return v != null && v.isNumber() ? v.numberValue().doubleValue() : null;
    }

    static @Nullable Boolean bool(JsonNode n, String key) {
        JsonNode v = n.get(key);
        if (v == null || v.isNull() || v.isMissingNode() || v.isContainer()) {
            return null;
        }
        if (v.isBoolean()) {
            return v.booleanValue();
        }
        if (v.isNumber()) {
            return v.numberValue().doubleValue() != 0;
        }
        return !v.asString().isEmpty();
    }

    static @Nullable OffsetDateTime dateTime(JsonNode n, String key) {
        JsonNode v = n.get(key);
        if (v == null || !v.isString()) {
            return null;
        }
        return parseDateTime(v.stringValue());
    }

    static @Nullable OffsetDateTime parseDateTime(@Nullable String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        String text = value.strip().toUpperCase(Locale.ROOT);
        Matcher m = FRACTION.matcher(text);
        if (m.find() && m.group(1).length() > 9) {
            text = text.substring(0, m.start(1)) + m.group(1).substring(0, 9) + text.substring(m.end(1));
        }
        try {
            return OffsetDateTime.parse(text, DateTimeFormatter.ISO_OFFSET_DATE_TIME);
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    static List<String> strings(JsonNode n, String key) {
        JsonNode v = n.get(key);
        if (v == null || !v.isArray()) {
            return List.of();
        }
        List<String> out = new ArrayList<>();
        for (JsonNode item : v) {
            if (!item.isNull() && !item.isContainer()) {
                out.add(item.isString() ? item.stringValue() : item.asString());
            }
        }
        return out;
    }

    static Map<String, Double> doubles(JsonNode n, String key) {
        JsonNode v = n.get(key);
        if (v == null || !v.isObject()) {
            return Map.of();
        }
        Map<String, Double> out = new LinkedHashMap<>();
        for (Map.Entry<String, JsonNode> e : v.properties()) {
            if (e.getValue().isNumber()) {
                out.put(e.getKey(), e.getValue().numberValue().doubleValue());
            }
        }
        return out;
    }

    static <T> @Nullable T object(JsonNode n, String key, Function<JsonNode, T> factory) {
        JsonNode v = n.get(key);
        return v != null && v.isObject() ? factory.apply(v) : null;
    }

    static <T> List<T> list(JsonNode n, String key, Function<JsonNode, T> factory) {
        JsonNode v = n.get(key);
        if (v == null || !v.isArray()) {
            return List.of();
        }
        List<T> out = new ArrayList<>();
        for (JsonNode item : v) {
            if (item.isObject()) {
                out.add(factory.apply(item));
            }
        }
        return out;
    }

    static <T> Map<String, T> map(JsonNode n, String key, Function<JsonNode, T> factory) {
        JsonNode v = n.get(key);
        if (v == null || !v.isObject()) {
            return Map.of();
        }
        Map<String, T> out = new LinkedHashMap<>();
        for (Map.Entry<String, JsonNode> e : v.properties()) {
            if (e.getValue().isObject()) {
                out.put(e.getKey(), factory.apply(e.getValue()));
            }
        }
        return out;
    }

    static <T> List<T> copy(@Nullable List<T> value) {
        return value == null ? List.of() : Collections.unmodifiableList(new ArrayList<>(value));
    }

    static <K, V> Map<K, V> copy(@Nullable Map<K, V> value) {
        return value == null ? Map.of() : Collections.unmodifiableMap(new LinkedHashMap<>(value));
    }
}
