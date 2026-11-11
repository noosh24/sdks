package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.OffsetDateTime;
import java.util.List;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record TableAvailability(
        @Nullable OffsetDateTime startsAt,
        @Nullable OffsetDateTime endsAt,
        @Nullable Integer durationMinutes,
        @Nullable String openTime,
        @Nullable String closeTime,
        List<AvailableTable> tables,
        @JsonIgnore @Nullable JsonNode raw) {

    public TableAvailability {
        tables = Fields.copy(tables);
    }

    public static TableAvailability from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new TableAvailability(
                Fields.dateTime(n, "startsAt"),
                Fields.dateTime(n, "endsAt"),
                Fields.integer(n, "durationMinutes"),
                Fields.string(n, "openTime"),
                Fields.string(n, "closeTime"),
                Fields.list(n, "tables", AvailableTable::from),
                n);
    }
}
