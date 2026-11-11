package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Table(
        @Nullable String id,
        @Nullable String label,
        @Nullable String hallId,
        @Nullable String zone,
        @Nullable Integer seats,
        @Nullable String shape,
        @Nullable String status,
        @Nullable Integer guests,
        @Nullable String waiter,
        @Nullable String seatedSince,
        @Nullable Integer openOrders,
        @Nullable String billId,
        @Nullable Double billTotal,
        @Nullable Boolean billRequested,
        @Nullable Boolean billSettled,
        @Nullable String mergedInto,
        @JsonIgnore @Nullable JsonNode raw) {

    public static Table from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Table(
                Fields.string(n, "id"),
                Fields.string(n, "label"),
                Fields.string(n, "hallId"),
                Fields.string(n, "zone"),
                Fields.integer(n, "seats"),
                Fields.string(n, "shape"),
                Fields.string(n, "status"),
                Fields.integer(n, "guests"),
                Fields.string(n, "waiter"),
                Fields.string(n, "seatedSince"),
                Fields.integer(n, "openOrders"),
                Fields.string(n, "billId"),
                Fields.number(n, "billTotal"),
                Fields.bool(n, "billRequested"),
                Fields.bool(n, "billSettled"),
                Fields.string(n, "mergedInto"),
                n);
    }
}
