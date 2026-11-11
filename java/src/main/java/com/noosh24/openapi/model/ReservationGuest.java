package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record ReservationGuest(
        @Nullable String name,
        @Nullable String phone,
        @Nullable String email,
        @JsonIgnore @Nullable JsonNode raw) {

    public static ReservationGuest from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new ReservationGuest(
                Fields.string(n, "name"),
                Fields.string(n, "phone"),
                Fields.string(n, "email"),
                n);
    }
}
