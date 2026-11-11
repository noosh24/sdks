package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Features(
        @Nullable Boolean loyalty,
        @Nullable Boolean inventory,
        @JsonIgnore @Nullable JsonNode raw) {

    public static Features from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Features(
                Fields.bool(n, "loyalty"),
                Fields.bool(n, "inventory"),
                n);
    }
}
