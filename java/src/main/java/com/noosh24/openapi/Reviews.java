package com.noosh24.openapi;

import com.noosh24.openapi.model.Review;

public final class Reviews extends Resource {
    Reviews(Noosh24Client client) {
        super(client);
    }

    public Page<Review> list() {
        return list(ListParams.none());
    }

    public Page<Review> list(ListParams params) {
        return page("/reviews", Review::from, params.toQuery());
    }

    public PagedIterable<Review> iterate() {
        return iterate(ListParams.none());
    }

    public PagedIterable<Review> iterate(ListParams params) {
        return paginate("/reviews", Review::from, params.toQuery(), 100);
    }
}
