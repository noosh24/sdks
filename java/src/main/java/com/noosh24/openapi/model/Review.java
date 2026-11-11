package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.OffsetDateTime;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Review(
        @Nullable String id,
        @Nullable String author,
        @Nullable Double overall,
        @Nullable ReviewRatings ratings,
        @Nullable String body,
        @Nullable String visitType,
        @Nullable OffsetDateTime visitedOn,
        @Nullable Boolean verified,
        @Nullable String reply,
        @Nullable OffsetDateTime repliedAt,
        @Nullable OffsetDateTime createdAt,
        @JsonIgnore @Nullable JsonNode raw) {

    public static Review from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Review(
                Fields.string(n, "id"),
                Fields.string(n, "author"),
                Fields.number(n, "overall"),
                Fields.object(n, "ratings", ReviewRatings::from),
                Fields.string(n, "body"),
                Fields.string(n, "visitType"),
                Fields.dateTime(n, "visitedOn"),
                Fields.bool(n, "verified"),
                Fields.string(n, "reply"),
                Fields.dateTime(n, "repliedAt"),
                Fields.dateTime(n, "createdAt"),
                n);
    }
}
