package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record ProductTranslation(
        @Nullable String name,
        @Nullable String description,
        @JsonIgnore @Nullable JsonNode raw) {

    public static ProductTranslation from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new ProductTranslation(
                Fields.string(n, "name"),
                Fields.string(n, "description"),
                n);
    }
}
