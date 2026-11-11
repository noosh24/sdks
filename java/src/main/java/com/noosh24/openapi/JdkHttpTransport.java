package com.noosh24.openapi;

import java.io.IOException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

public final class JdkHttpTransport implements HttpTransport {
    private final HttpClient http;
    private final boolean owned;

    public JdkHttpTransport(HttpClient http) {
        this(http, false);
    }

    private JdkHttpTransport(HttpClient http, boolean owned) {
        this.http = http;
        this.owned = owned;
    }

    static JdkHttpTransport create(Duration connectTimeout) {
        HttpClient http = HttpClient.newBuilder()
                .connectTimeout(connectTimeout)
                .followRedirects(HttpClient.Redirect.NEVER)
                .build();
        return new JdkHttpTransport(http, true);
    }

    @Override
    public Response send(Request request) throws IOException, InterruptedException {
        byte[] body = request.body();
        HttpRequest.BodyPublisher publisher = body == null
                ? HttpRequest.BodyPublishers.noBody()
                : HttpRequest.BodyPublishers.ofByteArray(body);
        HttpRequest.Builder builder = HttpRequest.newBuilder(request.uri())
                .timeout(request.timeout())
                .method(request.method(), publisher);
        request.headers().forEach(builder::header);
        HttpResponse<byte[]> response = http.send(builder.build(), HttpResponse.BodyHandlers.ofByteArray());
        return new Response(response.statusCode(), response.headers().map(), response.body());
    }

    @Override
    public void close() {
        if (owned) {
            http.close();
        }
    }
}
