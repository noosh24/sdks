package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Hall(
        @Nullable String id,
        @Nullable String name,
        @Nullable Integer position,
        @JsonIgnore @Nullable JsonNode raw) {

    public static Hall from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Hall(
                Fields.string(n, "id"),
                Fields.string(n, "name"),
                Fields.integer(n, "position"),
                n);
    }
}
