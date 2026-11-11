package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.OffsetDateTime;
import java.util.List;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Order(
        @Nullable String id,
        @Nullable String number,
        @Nullable Integer dailyNumber,
        @Nullable String kind,
        @Nullable String orderType,
        @Nullable String status,
        @Nullable String tableId,
        @Nullable String billId,
        @Nullable String customerName,
        @Nullable String allergyNote,
        List<OrderItem> items,
        @Nullable Double subtotal,
        @Nullable OrderDelivery delivery,
        @Nullable OffsetDateTime createdAt,
        @Nullable OffsetDateTime updatedAt,
        @JsonIgnore @Nullable JsonNode raw) {

    public Order {
        items = Fields.copy(items);
    }

    public static Order from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Order(
                Fields.string(n, "id"),
                Fields.string(n, "number"),
                Fields.integer(n, "dailyNumber"),
                Fields.string(n, "kind"),
                Fields.string(n, "orderType"),
                Fields.string(n, "status"),
                Fields.string(n, "tableId"),
                Fields.string(n, "billId"),
                Fields.string(n, "customerName"),
                Fields.string(n, "allergyNote"),
                Fields.list(n, "items", OrderItem::from),
                Fields.number(n, "subtotal"),
                Fields.object(n, "delivery", OrderDelivery::from),
                Fields.dateTime(n, "createdAt"),
                Fields.dateTime(n, "updatedAt"),
                n);
    }
}
