package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record DeliveryPlatform(
        @Nullable String id,
        @Nullable String name,
        @Nullable String ref,
        @JsonIgnore @Nullable JsonNode raw) {

    public static DeliveryPlatform from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new DeliveryPlatform(
                Fields.string(n, "id"),
                Fields.string(n, "name"),
                Fields.string(n, "ref"),
                n);
    }
}
