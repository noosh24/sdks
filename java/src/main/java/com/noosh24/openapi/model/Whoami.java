package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record Whoami(
        @Nullable Restaurant restaurant,
        @Nullable ApiKeyInfo key,
        @Nullable Subscription subscription,
        @Nullable Features features,
        @JsonIgnore @Nullable JsonNode raw) {

    public static Whoami from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new Whoami(
                Fields.object(n, "restaurant", Restaurant::from),
                Fields.object(n, "key", ApiKeyInfo::from),
                Fields.object(n, "subscription", Subscription::from),
                Fields.object(n, "features", Features::from),
                n);
    }
}
