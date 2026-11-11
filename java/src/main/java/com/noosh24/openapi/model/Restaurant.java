package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Restaurant(
        @Nullable String id,
        @Nullable String name,
        @Nullable String slug,
        @JsonIgnore @Nullable JsonNode raw) {

    public static Restaurant from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Restaurant(
                Fields.string(n, "id"),
                Fields.string(n, "name"),
                Fields.string(n, "slug"),
                n);
    }
}
