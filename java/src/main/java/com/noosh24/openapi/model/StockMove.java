package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.OffsetDateTime;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record StockMove(
        @Nullable String id,
        @Nullable String ingredientId,
        @Nullable Double qty,
        @Nullable String reason,
        @Nullable String orderId,
        @Nullable String invoiceId,
        @Nullable String storeId,
        @Nullable String note,
        @Nullable OffsetDateTime createdAt,
        @JsonIgnore @Nullable JsonNode raw) {

    public static StockMove from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new StockMove(
                Fields.string(n, "id"),
                Fields.string(n, "ingredientId"),
                Fields.number(n, "qty"),
                Fields.string(n, "reason"),
                Fields.string(n, "orderId"),
                Fields.string(n, "invoiceId"),
                Fields.string(n, "storeId"),
                Fields.string(n, "note"),
                Fields.dateTime(n, "createdAt"),
                n);
    }
}
