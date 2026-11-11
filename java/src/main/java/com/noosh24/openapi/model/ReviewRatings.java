package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record ReviewRatings(
        @Nullable Double food,
        @Nullable Double service,
        @Nullable Double atmosphere,
        @Nullable Double cleanliness,
        @Nullable Double price,
        @JsonIgnore @Nullable JsonNode raw) {

    public static ReviewRatings from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new ReviewRatings(
                Fields.number(n, "food"),
                Fields.number(n, "service"),
                Fields.number(n, "atmosphere"),
                Fields.number(n, "cleanliness"),
                Fields.number(n, "price"),
                n);
    }
}
