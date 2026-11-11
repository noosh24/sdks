package com.noosh24.openapi;

public enum ProductExpand {
    MODIFIER_GROUPS("modifierGroups"),
    TRANSLATIONS("translations");

    private final String value;

    ProductExpand(String value) {
        this.value = value;
    }

    public String value() {
        return value;
    }

    @Override
    public String toString() {
        return value;
    }
}
