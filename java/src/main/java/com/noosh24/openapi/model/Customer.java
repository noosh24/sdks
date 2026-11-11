package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.OffsetDateTime;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Customer(
        @Nullable String id,
        @Nullable String name,
        @Nullable String phone,
        @Nullable String note,
        @Nullable OffsetDateTime createdAt,
        @Nullable OffsetDateTime updatedAt,
        @JsonIgnore @Nullable JsonNode raw) {

    public static Customer from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Customer(
                Fields.string(n, "id"),
                Fields.string(n, "name"),
                Fields.string(n, "phone"),
                Fields.string(n, "note"),
                Fields.dateTime(n, "createdAt"),
                Fields.dateTime(n, "updatedAt"),
                n);
    }
}
