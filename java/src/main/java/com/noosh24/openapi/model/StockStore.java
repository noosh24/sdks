package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.util.List;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record StockStore(
        @Nullable String id,
        @Nullable String name,
        @Nullable Boolean isDefault,
        List<String> stations,
        @JsonIgnore @Nullable JsonNode raw) {

    public StockStore {
        stations = Fields.copy(stations);
    }

    public static StockStore from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new StockStore(
                Fields.string(n, "id"),
                Fields.string(n, "name"),
                Fields.bool(n, "isDefault"),
                Fields.strings(n, "stations"),
                n);
    }
}
