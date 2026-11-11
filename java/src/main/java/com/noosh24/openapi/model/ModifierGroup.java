package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.util.List;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record ModifierGroup(
        @Nullable String id,
        @Nullable String name,
        @Nullable Boolean required,
        @Nullable Integer position,
        List<Modifier> modifiers,
        @JsonIgnore @Nullable JsonNode raw) {

    public ModifierGroup {
        modifiers = Fields.copy(modifiers);
    }

    public static ModifierGroup from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new ModifierGroup(
                Fields.string(n, "id"),
                Fields.string(n, "name"),
                Fields.bool(n, "required"),
                Fields.integer(n, "position"),
                Fields.list(n, "modifiers", Modifier::from),
                n);
    }
}
