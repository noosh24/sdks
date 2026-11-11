package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record StopListItem(
        @Nullable String id,
        @Nullable String name,
        @Nullable String category,
        @Nullable Double price,
        @JsonIgnore @Nullable JsonNode raw) {

    public static StopListItem from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new StopListItem(
                Fields.string(n, "id"),
                Fields.string(n, "name"),
                Fields.string(n, "category"),
                Fields.number(n, "price"),
                n);
    }
}
