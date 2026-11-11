package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record PaymentCard(
        @Nullable String maskedPan,
        @Nullable String scheme,
        @Nullable String bank,
        @JsonIgnore @Nullable JsonNode raw) {

    public static PaymentCard from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new PaymentCard(
                Fields.string(n, "maskedPan"),
                Fields.string(n, "scheme"),
                Fields.string(n, "bank"),
                n);
    }
}
