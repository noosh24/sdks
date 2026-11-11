package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record OrderItem(
        @Nullable String id,
        @Nullable String productId,
        @Nullable String name,
        @Nullable Integer qty,
        @Nullable Double price,
        @Nullable Double listPrice,
        @Nullable String modifiers,
        @Nullable String note,
        @Nullable String status,
        @Nullable Boolean comp,
        @Nullable String campaign,
        @Nullable String cancelReason,
        @JsonIgnore @Nullable JsonNode raw) {

    public static OrderItem from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new OrderItem(
                Fields.string(n, "id"),
                Fields.string(n, "productId"),
                Fields.string(n, "name"),
                Fields.integer(n, "qty"),
                Fields.number(n, "price"),
                Fields.number(n, "listPrice"),
                Fields.string(n, "modifiers"),
                Fields.string(n, "note"),
                Fields.string(n, "status"),
                Fields.bool(n, "comp"),
                Fields.string(n, "campaign"),
                Fields.string(n, "cancelReason"),
                n);
    }
}
