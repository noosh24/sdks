package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.OffsetDateTime;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record LoyaltyCard(
        @Nullable String id,
        @Nullable String name,
        @Nullable String phone,
        @Nullable Integer stamps,
        @Nullable Integer totalStamps,
        @Nullable Integer redeemed,
        @Nullable String source,
        @Nullable OffsetDateTime lastVisitAt,
        @Nullable OffsetDateTime createdAt,
        @Nullable OffsetDateTime updatedAt,
        @JsonIgnore @Nullable JsonNode raw) {

    public static LoyaltyCard from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new LoyaltyCard(
                Fields.string(n, "id"),
                Fields.string(n, "name"),
                Fields.string(n, "phone"),
                Fields.integer(n, "stamps"),
                Fields.integer(n, "totalStamps"),
                Fields.integer(n, "redeemed"),
                Fields.string(n, "source"),
                Fields.dateTime(n, "lastVisitAt"),
                Fields.dateTime(n, "createdAt"),
                Fields.dateTime(n, "updatedAt"),
                n);
    }
}
