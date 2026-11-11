package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.util.List;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record ApiKeyInfo(
        @Nullable String id,
        @Nullable String name,
        @Nullable String prefix,
        List<String> scopes,
        @JsonIgnore @Nullable JsonNode raw) {

    public ApiKeyInfo {
        scopes = Fields.copy(scopes);
    }

    public static ApiKeyInfo from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new ApiKeyInfo(
                Fields.string(n, "id"),
                Fields.string(n, "name"),
                Fields.string(n, "prefix"),
                Fields.strings(n, "scopes"),
                n);
    }
}
