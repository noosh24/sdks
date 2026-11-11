package com.noosh24.openapi;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.jspecify.annotations.Nullable;

public final class ListParams {
    private static final ListParams NONE = builder().build();

    private final @Nullable Integer limit;
    private final @Nullable Integer offset;
    private final List<String> sort;
    private final @Nullable String where;

    private ListParams(Builder b) {
        this.limit = b.limit;
        this.offset = b.offset;
        this.sort = List.copyOf(b.sort);
        this.where = b.where;
    }

    public static Builder builder() {
        return new Builder();
    }

    public static ListParams none() {
        return NONE;
    }

    public @Nullable Integer limit() {
        return limit;
    }

    public @Nullable Integer offset() {
        return offset;
    }

    public List<String> sort() {
        return sort;
    }

    public @Nullable String where() {
        return where;
    }

    Query toQuery() {
        return query(limit, offset, sort, where);
    }

    static Query query(@Nullable Integer limit, @Nullable Integer offset, List<String> sort, @Nullable String where) {
        Query q = new Query().add("limit", limit).add("offset", offset);
        if (!sort.isEmpty()) {
            q.add("sort", sort);
        }
        if (where != null && !where.isEmpty()) {
            q.add("where", where);
        }
        return q;
    }

    static List<String> sorts(String... sort) {
        List<String> out = new ArrayList<>();
        for (String s : Arrays.asList(sort)) {
            if (s != null && !s.isEmpty()) {
                out.add(s);
            }
        }
        return out;
    }

    public static final class Builder {
        private @Nullable Integer limit;
        private @Nullable Integer offset;
        private List<String> sort = List.of();
        private @Nullable String where;

        private Builder() {}

        public Builder limit(@Nullable Integer limit) {
            this.limit = limit;
            return this;
        }

        public Builder offset(@Nullable Integer offset) {
            this.offset = offset;
            return this;
        }

        public Builder sort(String... sort) {
            this.sort = sorts(sort);
            return this;
        }

        public Builder sort(List<String> sort) {
            return sort(sort.toArray(String[]::new));
        }

        public Builder where(@Nullable String where) {
            this.where = where;
            return this;
        }

        public Builder where(@Nullable Where where) {
            this.where = where == null ? null : where.toString();
            return this;
        }

        public ListParams build() {
            return new ListParams(this);
        }
    }
}
