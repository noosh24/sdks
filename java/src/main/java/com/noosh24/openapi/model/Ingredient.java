package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.OffsetDateTime;
import java.util.Map;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Ingredient(
        @Nullable String id,
        @Nullable String name,
        @Nullable String unit,
        @Nullable Double stock,
        @Nullable Double onOpenBills,
        @Nullable Double available,
        @Nullable String state,
        @Nullable Double lowStock,
        @Nullable Double parStock,
        @Nullable Double costPerUnit,
        @Nullable Double value,
        @Nullable Boolean prepared,
        Map<String, Double> byStore,
        @Nullable OffsetDateTime updatedAt,
        @JsonIgnore @Nullable JsonNode raw) {

    public Ingredient {
        byStore = Fields.copy(byStore);
    }

    public static Ingredient from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Ingredient(
                Fields.string(n, "id"),
                Fields.string(n, "name"),
                Fields.string(n, "unit"),
                Fields.number(n, "stock"),
                Fields.number(n, "onOpenBills"),
                Fields.number(n, "available"),
                Fields.string(n, "state"),
                Fields.number(n, "lowStock"),
                Fields.number(n, "parStock"),
                Fields.number(n, "costPerUnit"),
                Fields.number(n, "value"),
                Fields.bool(n, "prepared"),
                Fields.doubles(n, "byStore"),
                Fields.dateTime(n, "updatedAt"),
                n);
    }
}
