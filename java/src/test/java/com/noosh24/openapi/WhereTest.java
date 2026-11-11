package com.noosh24.openapi;

import static com.noosh24.openapi.Where.where;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import org.junit.jupiter.api.Test;

class WhereTest {
    @Test
    void buildsAndOnlyConditions() {
        String text = where()
                .eq("category", "Salads")
                .ne("station", "")
                .gt("price", 4.75)
                .lte("prepMinutes", 15)
                .eq("vegetarian", false)
                .gte("createdAt", OffsetDateTime.of(2026, 11, 1, 18, 0, 0, 0, ZoneOffset.ofHours(4)))
                .lt("price", 20.0)
                .in("id", "7f0c", "O'Neil", 3)
                .toString();

        assertEquals("category = 'Salads' AND station != '' AND price > 4.75 AND prepMinutes <= 15 AND vegetarian = false"
                + " AND createdAt >= '2026-11-01T18:00:00+04:00' AND price < 20 AND id in ('7f0c', 'O''Neil', 3)", text);
    }

    @Test
    void quotesDatesAndOtherNumbers() {
        String text = where()
                .lt("visitedOn", LocalDate.of(2026, 11, 2))
                .gte("createdAt", Instant.parse("2026-11-01T14:00:00Z"))
                .eq("stock", 12L)
                .eq("cost", new BigDecimal("2.50"))
                .eq("ratio", 0.5f)
                .in("zone", List.of("Terrace", "Chef's table"))
                .toString();

        assertEquals("visitedOn < '2026-11-02' AND createdAt >= '2026-11-01T14:00:00Z' AND stock = 12 AND cost = 2.5"
                + " AND ratio = 0.5 AND zone in ('Terrace', 'Chef''s table')", text);
    }

    @Test
    void emptyIsEmptyString() {
        assertEquals("", new Where().toString());
    }

    @Test
    void rejectsBadInput() {
        assertThrows(IllegalArgumentException.class, () -> where().eq("price = 1 OR 1", 1));
        assertThrows(IllegalArgumentException.class, () -> where().eq("", 1));
        assertThrows(IllegalArgumentException.class, () -> where().in("id", List.of()));
        assertThrows(IllegalArgumentException.class, () -> where().in("id"));
        assertThrows(IllegalArgumentException.class, () -> where().gt("price", Double.NaN));
        assertThrows(IllegalArgumentException.class, () -> where().gt("price", Double.POSITIVE_INFINITY));
        assertThrows(IllegalArgumentException.class, () -> where().gt("createdAt", LocalDateTime.of(2026, 11, 1, 0, 0)));
        assertThrows(IllegalArgumentException.class, () -> Where.literal(null));
        assertThrows(IllegalArgumentException.class, () -> Where.literal(new Object()));
    }
}
