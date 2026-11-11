package com.noosh24.openapi;

import com.noosh24.openapi.model.Whoami;
import java.io.IOException;
import java.net.SocketTimeoutException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpTimeoutException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import org.jspecify.annotations.Nullable;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;

public final class Noosh24Client implements AutoCloseable {
    public static final String VERSION = "0.1.0";
    public static final String DEFAULT_BASE_URL = "https://open-api.noosh24.com/v1";
    public static final Duration DEFAULT_TIMEOUT = Duration.ofSeconds(30);
    public static final int DEFAULT_MAX_RETRIES = 2;

    private static final Set<Integer> RETRY_STATUSES = Set.of(429, 502, 503, 504);
    private static final double MAX_RETRY_WAIT_SECONDS = 60;

    private final String apiKey;
    private final String baseUrl;
    private final Duration timeout;
    private final int maxRetries;
    private final String userAgent;
    private final HttpTransport transport;
    private final boolean ownsTransport;
    private final Sleeper sleeper;

    private final Menu menu;
    private final Reservations reservations;
    private final Orders orders;
    private final Payments payments;
    private final Tables tables;
    private final Customers customers;
    private final Loyalty loyalty;
    private final Stock stock;
    private final Reviews reviews;

    public Noosh24Client(String apiKey) {
        this(builder().apiKey(apiKey));
    }

    private Noosh24Client(Builder b) {
        String key = b.apiKey == null ? "" : b.apiKey.strip();
        if (key.isEmpty()) {
            throw new IllegalArgumentException("An API key is required");
        }
        if (b.timeout.isNegative() || b.timeout.isZero()) {
            throw new IllegalArgumentException("timeout must be positive");
        }
        this.apiKey = key;
        this.baseUrl = stripSlashes(b.baseUrl == null || b.baseUrl.isBlank() ? DEFAULT_BASE_URL : b.baseUrl.strip());
        this.timeout = b.timeout;
        this.maxRetries = Math.max(0, b.maxRetries);
        String agent = "noosh24-java/" + VERSION;
        this.userAgent = b.userAgent == null || b.userAgent.isBlank() ? agent : b.userAgent.strip() + " " + agent;
        if (b.transport != null) {
            this.transport = b.transport;
            this.ownsTransport = false;
        } else if (b.httpClient != null) {
            this.transport = new JdkHttpTransport(b.httpClient);
            this.ownsTransport = false;
        } else {
            this.transport = JdkHttpTransport.create(b.timeout);
            this.ownsTransport = true;
        }
        this.sleeper = b.sleeper;

        this.menu = new Menu(this);
        this.reservations = new Reservations(this);
        this.orders = new Orders(this);
        this.payments = new Payments(this);
        this.tables = new Tables(this);
        this.customers = new Customers(this);
        this.loyalty = new Loyalty(this);
        this.stock = new Stock(this);
        this.reviews = new Reviews(this);
    }

    public static Builder builder() {
        return new Builder();
    }

    public Whoami whoami() {
        return Whoami.from(request("GET", "/whoami", null, null, true).data());
    }

    public Menu menu() {
        return menu;
    }

    public Reservations reservations() {
        return reservations;
    }

    public Orders orders() {
        return orders;
    }

    public Payments payments() {
        return payments;
    }

    public Tables tables() {
        return tables;
    }

    public Customers customers() {
        return customers;
    }

    public Loyalty loyalty() {
        return loyalty;
    }

    public Stock stock() {
        return stock;
    }

    public Reviews reviews() {
        return reviews;
    }

    public String baseUrl() {
        return baseUrl;
    }

    public String userAgent() {
        return userAgent;
    }

    @Override
    public void close() {
        if (ownsTransport) {
            transport.close();
        }
    }

    record Result(int status, @Nullable JsonNode data) {}

    Result request(String method, String path, @Nullable Query query, @Nullable JsonNode body, boolean retryable) {
        String encoded = query == null ? "" : query.encode();
        URI uri = URI.create(baseUrl + path + (encoded.isEmpty() ? "" : "?" + encoded));
        Map<String, String> headers = new LinkedHashMap<>();
        headers.put("Authorization", "Bearer " + apiKey);
        headers.put("Accept", "application/json");
        headers.put("User-Agent", userAgent);
        byte[] payload = null;
        if (body != null) {
            headers.put("Content-Type", "application/json");
            payload = JsonSupport.MAPPER.writeValueAsBytes(body);
        }
        HttpTransport.Request request = new HttpTransport.Request(method, uri, headers, payload, timeout);

        for (int attempt = 0; ; attempt++) {
            HttpTransport.Response response;
            try {
                response = transport.send(request);
            } catch (HttpTimeoutException | SocketTimeoutException e) {
                if (retryable && attempt < maxRetries) {
                    pause(backoff(attempt));
                    continue;
                }
                throw new ApiTimeoutException("Request timed out after " + timeout.toMillis() + " ms", e);
            } catch (IOException e) {
                if (retryable && attempt < maxRetries) {
                    pause(backoff(attempt));
                    continue;
                }
                throw new ApiConnectionException("Could not reach the Noosh24 API: " + e.getMessage(), e);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new ApiConnectionException("Interrupted while calling the Noosh24 API", e);
            }

            Map<String, String> responseHeaders = lowerCase(response.headers());
            String text = response.bodyAsString();
            int status = response.status();
            if (status >= 200 && status < 300) {
                return new Result(status, decode(status, responseHeaders, text));
            }
            Duration wait = retryWait(status, responseHeaders, attempt);
            if (retryable && attempt < maxRetries && wait != null) {
                pause(wait);
                continue;
            }
            throw Errors.fromResponse(status, responseHeaders, text);
        }
    }

    private void pause(Duration duration) {
        try {
            sleeper.sleep(duration);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ApiConnectionException("Interrupted while waiting to retry", e);
        }
    }

    private static @Nullable JsonNode decode(int status, Map<String, String> headers, String text) {
        if (text.isEmpty()) {
            return null;
        }
        JsonNode parsed;
        try {
            parsed = JsonSupport.MAPPER.readTree(text);
        } catch (JacksonException e) {
            throw new ApiException(status, null, "The API answered with a body that is not JSON", headers, text);
        }
        if (parsed == null || !parsed.isObject() || !parsed.has("data")) {
            throw new ApiException(status, null, "The API answered without a \"data\" field", headers, text);
        }
        return parsed.get("data");
    }

    private static Map<String, String> lowerCase(Map<String, List<String>> headers) {
        Map<String, String> out = new LinkedHashMap<>();
        headers.forEach((name, values) -> {
            if (name != null && values != null) {
                out.merge(name.toLowerCase(Locale.ROOT), String.join(", ", values), (a, b) -> a + ", " + b);
            }
        });
        return out;
    }

    private static @Nullable Duration retryWait(int status, Map<String, String> headers, int attempt) {
        if (!RETRY_STATUSES.contains(status)) {
            return null;
        }
        String header = headers.get("retry-after");
        if (header != null && !header.isBlank()) {
            double seconds;
            try {
                seconds = Double.parseDouble(header.strip());
            } catch (NumberFormatException e) {
                return backoff(attempt);
            }
            if (!Double.isFinite(seconds)) {
                return backoff(attempt);
            }
            seconds = Math.max(0, seconds);
            return seconds <= MAX_RETRY_WAIT_SECONDS ? Duration.ofMillis(Math.round(seconds * 1000)) : null;
        }
        return backoff(attempt);
    }

    static Duration backoff(int attempt) {
        return Duration.ofMillis((long) (Math.min(8.0, 0.5 * Math.pow(2, attempt)) * 1000));
    }

    private static String stripSlashes(String url) {
        int end = url.length();
        while (end > 0 && url.charAt(end - 1) == '/') {
            end--;
        }
        return url.substring(0, end);
    }

    public static final class Builder {
        private @Nullable String apiKey;
        private @Nullable String baseUrl;
        private Duration timeout = DEFAULT_TIMEOUT;
        private int maxRetries = DEFAULT_MAX_RETRIES;
        private @Nullable String userAgent;
        private @Nullable HttpTransport transport;
        private @Nullable HttpClient httpClient;
        private Sleeper sleeper = Thread::sleep;

        private Builder() {}

        public Builder apiKey(String apiKey) {
            this.apiKey = apiKey;
            return this;
        }

        public Builder baseUrl(@Nullable String baseUrl) {
            this.baseUrl = baseUrl;
            return this;
        }

        public Builder timeout(Duration timeout) {
            this.timeout = timeout;
            return this;
        }

        public Builder maxRetries(int maxRetries) {
            this.maxRetries = maxRetries;
            return this;
        }

        public Builder userAgent(@Nullable String userAgent) {
            this.userAgent = userAgent;
            return this;
        }

        public Builder transport(@Nullable HttpTransport transport) {
            this.transport = transport;
            return this;
        }

        public Builder httpClient(@Nullable HttpClient httpClient) {
            this.httpClient = httpClient;
            return this;
        }

        public Builder sleeper(Sleeper sleeper) {
            this.sleeper = sleeper;
            return this;
        }

        public Noosh24Client build() {
            return new Noosh24Client(this);
        }
    }
}
