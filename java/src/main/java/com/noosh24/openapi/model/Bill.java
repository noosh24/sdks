package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.OffsetDateTime;
import java.util.List;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Bill(
        @Nullable String id,
        @Nullable String tableId,
        @Nullable String status,
        @Nullable Integer guests,
        @Nullable String waiter,
        @Nullable String customerId,
        @Nullable String reservationId,
        List<String> orderIds,
        @Nullable Double subtotal,
        @Nullable Double discountPercent,
        @Nullable Double billDiscount,
        @Nullable Double serviceFeePercent,
        @Nullable Double serviceFee,
        @Nullable Double total,
        @Nullable Double paid,
        @Nullable Double remaining,
        @Nullable OffsetDateTime openedAt,
        @Nullable OffsetDateTime closedAt,
        @JsonIgnore @Nullable JsonNode raw) {

    public Bill {
        orderIds = Fields.copy(orderIds);
    }

    public static Bill from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Bill(
                Fields.string(n, "id"),
                Fields.string(n, "tableId"),
                Fields.string(n, "status"),
                Fields.integer(n, "guests"),
                Fields.string(n, "waiter"),
                Fields.string(n, "customerId"),
                Fields.string(n, "reservationId"),
                Fields.strings(n, "orderIds"),
                Fields.number(n, "subtotal"),
                Fields.number(n, "discountPercent"),
                Fields.number(n, "billDiscount"),
                Fields.number(n, "serviceFeePercent"),
                Fields.number(n, "serviceFee"),
                Fields.number(n, "total"),
                Fields.number(n, "paid"),
                Fields.number(n, "remaining"),
                Fields.dateTime(n, "openedAt"),
                Fields.dateTime(n, "closedAt"),
                n);
    }
}
