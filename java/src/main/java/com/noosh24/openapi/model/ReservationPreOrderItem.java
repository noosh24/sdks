package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record ReservationPreOrderItem(
        @Nullable String productId,
        @Nullable String name,
        @Nullable Double price,
        @Nullable Integer qty,
        @Nullable String note,
        @JsonIgnore @Nullable JsonNode raw) {

    public static ReservationPreOrderItem from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new ReservationPreOrderItem(
                Fields.string(n, "productId"),
                Fields.string(n, "name"),
                Fields.number(n, "price"),
                Fields.integer(n, "qty"),
                Fields.string(n, "note"),
                n);
    }
}
