package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.util.List;
import java.util.Map;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Product(
        @Nullable String id,
        @Nullable String name,
        @Nullable String category,
        @Nullable String description,
        @Nullable Double price,
        @Nullable Boolean available,
        @Nullable Boolean popular,
        @Nullable Integer position,
        @Nullable Integer prepMinutes,
        @Nullable String station,
        @Nullable Double vatRate,
        @Nullable Boolean vegetarian,
        @Nullable Boolean spicy,
        List<String> allergens,
        @Nullable Boolean discountable,
        @Nullable Boolean hasModifiers,
        @Nullable String image,
        @Nullable String video,
        List<ModifierGroup> modifierGroups,
        Map<String, ProductTranslation> translations,
        @JsonIgnore @Nullable JsonNode raw) {

    public Product {
        allergens = Fields.copy(allergens);
        modifierGroups = Fields.copy(modifierGroups);
        translations = Fields.copy(translations);
    }

    public static Product from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Product(
                Fields.string(n, "id"),
                Fields.string(n, "name"),
                Fields.string(n, "category"),
                Fields.string(n, "description"),
                Fields.number(n, "price"),
                Fields.bool(n, "available"),
                Fields.bool(n, "popular"),
                Fields.integer(n, "position"),
                Fields.integer(n, "prepMinutes"),
                Fields.string(n, "station"),
                Fields.number(n, "vatRate"),
                Fields.bool(n, "vegetarian"),
                Fields.bool(n, "spicy"),
                Fields.strings(n, "allergens"),
                Fields.bool(n, "discountable"),
                Fields.bool(n, "hasModifiers"),
                Fields.string(n, "image"),
                Fields.string(n, "video"),
                Fields.list(n, "modifierGroups", ModifierGroup::from),
                Fields.map(n, "translations", ProductTranslation::from),
                n);
    }
}
