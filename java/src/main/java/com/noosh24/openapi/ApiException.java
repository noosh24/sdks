package com.noosh24.openapi;

import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;
import org.jspecify.annotations.Nullable;

public class ApiException extends Noosh24Exception {
    private final int status;
    private final @Nullable String code;
    private final Map<String, String> headers;
    private final String body;

    public ApiException(int status, @Nullable String code, String message, Map<String, String> headers, String body) {
        super(message);
        this.status = status;
        this.code = code;
        Map<String, String> lower = new TreeMap<>();
        headers.forEach((name, value) -> lower.put(name.toLowerCase(Locale.ROOT), value));
        this.headers = Map.copyOf(lower);
        this.body = body;
    }

    public int getStatus() {
        return status;
    }

    public @Nullable String getCode() {
        return code;
    }

    public Map<String, String> getHeaders() {
        return headers;
    }

    public String getBody() {
        return body;
    }

    @Override
    public String toString() {
        return getClass().getSimpleName() + "(status=" + status + ", code=" + code + ", message=" + getMessage() + ")";
    }
}
