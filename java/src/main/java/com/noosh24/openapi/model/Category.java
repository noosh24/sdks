package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Category(
        @Nullable String name,
        @Nullable Integer position,
        @Nullable Integer products,
        @Nullable Integer available,
        @JsonIgnore @Nullable JsonNode raw) {

    public static Category from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Category(
                Fields.string(n, "name"),
                Fields.integer(n, "position"),
                Fields.integer(n, "products"),
                Fields.integer(n, "available"),
                n);
    }
}
