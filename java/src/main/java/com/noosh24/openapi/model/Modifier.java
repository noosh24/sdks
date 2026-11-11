package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Modifier(
        @Nullable String id,
        @Nullable String name,
        @Nullable Double priceDelta,
        @Nullable Integer position,
        @JsonIgnore @Nullable JsonNode raw) {

    public static Modifier from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Modifier(
                Fields.string(n, "id"),
                Fields.string(n, "name"),
                Fields.number(n, "priceDelta"),
                Fields.integer(n, "position"),
                n);
    }
}
