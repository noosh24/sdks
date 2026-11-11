package com.noosh24.openapi;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.StringJoiner;
import java.util.regex.Pattern;
import org.jspecify.annotations.Nullable;

public final class Where {
    private static final Pattern FIELD = Pattern.compile("^[A-Za-z][A-Za-z0-9_.]*$");

    private final List<String> conditions = new ArrayList<>();

    public static Where where() {
        return new Where();
    }

    public Where eq(String field, Object value) {
        return add(field, "=", value);
    }

    public Where ne(String field, Object value) {
        return add(field, "!=", value);
    }

    public Where gt(String field, Object value) {
        return add(field, ">", value);
    }

    public Where gte(String field, Object value) {
        return add(field, ">=", value);
    }

    public Where lt(String field, Object value) {
        return add(field, "<", value);
    }

    public Where lte(String field, Object value) {
        return add(field, "<=", value);
    }

    public Where in(String field, Collection<?> values) {
        String name = field(field);
        if (values == null || values.isEmpty()) {
            throw new IllegalArgumentException("in() needs at least one value");
        }
        StringJoiner list = new StringJoiner(", ", "(", ")");
        for (Object value : values) {
            list.add(literal(value));
        }
        conditions.add(name + " in " + list);
        return this;
    }

    public Where in(String field, Object... values) {
        return in(field, values == null ? List.of() : Arrays.asList(values));
    }

    public boolean isEmpty() {
        return conditions.isEmpty();
    }

    @Override
    public String toString() {
        return String.join(" AND ", conditions);
    }

    public static String literal(@Nullable Object value) {
        if (value == null) {
            throw new IllegalArgumentException("where does not take null");
        }
        if (value instanceof Boolean b) {
            return b ? "true" : "false";
        }
        if (value instanceof Integer || value instanceof Long || value instanceof Short || value instanceof Byte
                || value instanceof BigInteger) {
            return value.toString();
        }
        if (value instanceof Double d) {
            return decimal(d);
        }
        if (value instanceof Float f) {
            if (!Float.isFinite(f)) {
                throw new IllegalArgumentException("Numbers in where must be finite");
            }
            return plain(new BigDecimal(Float.toString(f)));
        }
        if (value instanceof BigDecimal d) {
            return plain(d);
        }
        if (value instanceof CharSequence || value instanceof Character) {
            return "'" + value.toString().replace("'", "''") + "'";
        }
        if (value instanceof OffsetDateTime t) {
            return "'" + t.format(DateTimeFormatter.ISO_OFFSET_DATE_TIME) + "'";
        }
        if (value instanceof ZonedDateTime t) {
            return "'" + t.toOffsetDateTime().format(DateTimeFormatter.ISO_OFFSET_DATE_TIME) + "'";
        }
        if (value instanceof Instant t) {
            return "'" + DateTimeFormatter.ISO_INSTANT.format(t) + "'";
        }
        if (value instanceof LocalDateTime) {
            throw new IllegalArgumentException("where needs a date-time with an offset, not a LocalDateTime");
        }
        if (value instanceof LocalDate d) {
            return "'" + d + "'";
        }
        throw new IllegalArgumentException("where takes strings, numbers, booleans and dates, not " + value.getClass().getName());
    }

    private static String decimal(double d) {
        if (!Double.isFinite(d)) {
            throw new IllegalArgumentException("Numbers in where must be finite");
        }
        return plain(BigDecimal.valueOf(d));
    }

    private static String plain(BigDecimal d) {
        return d.signum() == 0 ? "0" : d.stripTrailingZeros().toPlainString();
    }

    private static String field(String name) {
        if (name == null || !FIELD.matcher(name).matches()) {
            throw new IllegalArgumentException("\"" + name + "\" is not a field name");
        }
        return name;
    }

    private Where add(String field, String operator, Object value) {
        conditions.add(field(field) + " " + operator + " " + literal(value));
        return this;
    }
}
