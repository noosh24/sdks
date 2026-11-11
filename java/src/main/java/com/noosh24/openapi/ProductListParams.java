package com.noosh24.openapi;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import org.jspecify.annotations.Nullable;

public final class ProductListParams {
    private static final ProductListParams NONE = builder().build();

    private final @Nullable Integer limit;
    private final @Nullable Integer offset;
    private final List<String> sort;
    private final @Nullable String where;
    private final List<ProductExpand> expand;

    private ProductListParams(Builder b) {
        this.limit = b.limit;
        this.offset = b.offset;
        this.sort = List.copyOf(b.sort);
        this.where = b.where;
        this.expand = List.copyOf(b.expand);
    }

    public static Builder builder() {
        return new Builder();
    }

    public static ProductListParams none() {
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

    public List<ProductExpand> expand() {
        return expand;
    }

    Query toQuery() {
        Query q = ListParams.query(limit, offset, sort, where);
        if (!expand.isEmpty()) {
            q.add("expand", expandValues(expand));
        }
        return q;
    }

    static List<String> expandValues(List<ProductExpand> expand) {
        List<String> out = new ArrayList<>();
        for (ProductExpand e : expand) {
            out.add(e.value());
        }
        return out;
    }

    public static final class Builder {
        private @Nullable Integer limit;
        private @Nullable Integer offset;
        private List<String> sort = List.of();
        private @Nullable String where;
        private List<ProductExpand> expand = List.of();

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
            this.sort = ListParams.sorts(sort);
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

        public Builder expand(ProductExpand... expand) {
            this.expand = List.copyOf(Arrays.asList(expand));
            return this;
        }

        public Builder expand(List<ProductExpand> expand) {
            this.expand = List.copyOf(expand);
            return this;
        }

        public ProductListParams build() {
            return new ProductListParams(this);
        }
    }
}
