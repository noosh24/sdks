package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.OffsetDateTime;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Payment(
        @Nullable String id,
        @Nullable String status,
        @Nullable String method,
        @Nullable String recordedMethod,
        @Nullable Double amount,
        @Nullable Double tip,
        @Nullable Double refundedAmount,
        @Nullable OffsetDateTime refundedAt,
        @Nullable String refundReason,
        @Nullable String billId,
        @Nullable String reservationId,
        @Nullable String orderId,
        @Nullable String takenAt,
        @Nullable PaymentCard card,
        @Nullable PaymentPlatform platform,
        @Nullable OffsetDateTime createdAt,
        @Nullable OffsetDateTime settledAt,
        @JsonIgnore @Nullable JsonNode raw) {

    public static Payment from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Payment(
                Fields.string(n, "id"),
                Fields.string(n, "status"),
                Fields.string(n, "method"),
                Fields.string(n, "recordedMethod"),
                Fields.number(n, "amount"),
                Fields.number(n, "tip"),
                Fields.number(n, "refundedAmount"),
                Fields.dateTime(n, "refundedAt"),
                Fields.string(n, "refundReason"),
                Fields.string(n, "billId"),
                Fields.string(n, "reservationId"),
                Fields.string(n, "orderId"),
                Fields.string(n, "takenAt"),
                Fields.object(n, "card", PaymentCard::from),
                Fields.object(n, "platform", PaymentPlatform::from),
                Fields.dateTime(n, "createdAt"),
                Fields.dateTime(n, "settledAt"),
                n);
    }
}
