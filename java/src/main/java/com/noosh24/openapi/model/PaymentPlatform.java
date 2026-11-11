package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record PaymentPlatform(
        @Nullable String id,
        @Nullable String name,
        @JsonIgnore @Nullable JsonNode raw) {

    public static PaymentPlatform from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new PaymentPlatform(
                Fields.string(n, "id"),
                Fields.string(n, "name"),
                n);
    }
}
