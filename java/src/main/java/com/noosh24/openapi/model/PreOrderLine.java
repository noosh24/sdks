package com.noosh24.openapi.model;

import org.jspecify.annotations.Nullable;

public record PreOrderLine(String itemId, int qty, @Nullable String note) {

    public PreOrderLine {
        if (itemId == null || itemId.isBlank()) {
            throw new IllegalArgumentException("A pre-order line needs an itemId");
        }
    }

    public PreOrderLine(String itemId, int qty) {
        this(itemId, qty, null);
    }
}
