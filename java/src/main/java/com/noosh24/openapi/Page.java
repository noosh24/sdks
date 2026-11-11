package com.noosh24.openapi;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;

public record Page<T>(List<T> items, int total, int limit, int offset) implements Iterable<T> {

    public Page {
        items = Collections.unmodifiableList(new ArrayList<>(items));
    }

    public boolean hasMore() {
        return !items.isEmpty() && offset + items.size() < total;
    }

    public int nextOffset() {
        return offset + items.size();
    }

    public int size() {
        return items.size();
    }

    @Override
    public Iterator<T> iterator() {
        return items.iterator();
    }
}
