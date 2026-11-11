package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record ReservationTable(
        @Nullable String id,
        @Nullable String label,
        @JsonIgnore @Nullable JsonNode raw) {

    public static ReservationTable from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new ReservationTable(
                Fields.string(n, "id"),
                Fields.string(n, "label"),
                n);
    }
}
