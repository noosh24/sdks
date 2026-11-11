package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.OffsetDateTime;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record OrderDelivery(
        @Nullable String status,
        @Nullable DeliveryPlatform platform,
        @Nullable String address,
        @Nullable String customerPhone,
        @Nullable String courierName,
        @Nullable String note,
        @Nullable String paymentMethod,
        @Nullable Double fee,
        @Nullable Double platformTotal,
        @Nullable OffsetDateTime acceptedAt,
        @JsonIgnore @Nullable JsonNode raw) {

    public static OrderDelivery from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new OrderDelivery(
                Fields.string(n, "status"),
                Fields.object(n, "platform", DeliveryPlatform::from),
                Fields.string(n, "address"),
                Fields.string(n, "customerPhone"),
                Fields.string(n, "courierName"),
                Fields.string(n, "note"),
                Fields.string(n, "paymentMethod"),
                Fields.number(n, "fee"),
                Fields.number(n, "platformTotal"),
                Fields.dateTime(n, "acceptedAt"),
                n);
    }
}
