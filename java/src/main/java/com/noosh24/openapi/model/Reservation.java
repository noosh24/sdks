package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.OffsetDateTime;
import java.util.List;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Reservation(
        @Nullable String id,
        @Nullable String code,
        @Nullable String status,
        @Nullable String source,
        @Nullable OffsetDateTime startsAt,
        @Nullable OffsetDateTime endsAt,
        @Nullable Integer guests,
        @Nullable String zone,
        @Nullable ReservationTable table,
        @Nullable ReservationGuest guest,
        @Nullable String specialRequest,
        @Nullable String allergyNote,
        @Nullable Boolean birthday,
        @Nullable Boolean childChair,
        @Nullable Double depositPaid,
        List<ReservationPreOrderItem> preOrder,
        @Nullable String externalRef,
        @Nullable OffsetDateTime decidedAt,
        @Nullable OffsetDateTime createdAt,
        @Nullable OffsetDateTime updatedAt,
        @JsonIgnore @Nullable JsonNode raw) {

    public Reservation {
        preOrder = Fields.copy(preOrder);
    }

    public static Reservation from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Reservation(
                Fields.string(n, "id"),
                Fields.string(n, "code"),
                Fields.string(n, "status"),
                Fields.string(n, "source"),
                Fields.dateTime(n, "startsAt"),
                Fields.dateTime(n, "endsAt"),
                Fields.integer(n, "guests"),
                Fields.string(n, "zone"),
                Fields.object(n, "table", ReservationTable::from),
                Fields.object(n, "guest", ReservationGuest::from),
                Fields.string(n, "specialRequest"),
                Fields.string(n, "allergyNote"),
                Fields.bool(n, "birthday"),
                Fields.bool(n, "childChair"),
                Fields.number(n, "depositPaid"),
                Fields.list(n, "preOrder", ReservationPreOrderItem::from),
                Fields.string(n, "externalRef"),
                Fields.dateTime(n, "decidedAt"),
                Fields.dateTime(n, "createdAt"),
                Fields.dateTime(n, "updatedAt"),
                n);
    }
}
