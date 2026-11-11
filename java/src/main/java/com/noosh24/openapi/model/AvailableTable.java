package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record AvailableTable(
        @Nullable String id,
        @Nullable String label,
        @Nullable String hallId,
        @Nullable String zone,
        @Nullable Integer seats,
        @Nullable Boolean free,
        @JsonIgnore @Nullable JsonNode raw) {

    public static AvailableTable from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new AvailableTable(
                Fields.string(n, "id"),
                Fields.string(n, "label"),
                Fields.string(n, "hallId"),
                Fields.string(n, "zone"),
                Fields.integer(n, "seats"),
                Fields.bool(n, "free"),
                n);
    }
}
