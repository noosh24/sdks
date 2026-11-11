package com.noosh24.openapi;

import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import org.jspecify.annotations.Nullable;

public interface HttpTransport extends AutoCloseable {

    Response send(Request request) throws IOException, InterruptedException;

    @Override
    default void close() {}

    record Request(String method, URI uri, Map<String, String> headers, byte @Nullable [] body, Duration timeout) {
        public Request {
            headers = Map.copyOf(headers);
        }

        public String bodyAsString() {
            return body == null ? "" : new String(body, StandardCharsets.UTF_8);
        }
    }

    record Response(int status, Map<String, List<String>> headers, byte[] body) {
        public Response {
            headers = Map.copyOf(headers);
        }

        public String bodyAsString() {
            return new String(body, StandardCharsets.UTF_8);
        }
    }
}
