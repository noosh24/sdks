package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.util.List;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Subscription(
        @Nullable String status,
        List<String> modules,
        @JsonIgnore @Nullable JsonNode raw) {

    public Subscription {
        modules = Fields.copy(modules);
    }

    public static Subscription from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Subscription(
                Fields.string(n, "status"),
                Fields.strings(n, "modules"),
                n);
    }
}
