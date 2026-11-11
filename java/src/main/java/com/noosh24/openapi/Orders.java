package com.noosh24.openapi;

import com.noosh24.openapi.model.Bill;
import com.noosh24.openapi.model.Order;

public final class Orders extends Resource {
    Orders(Noosh24Client client) {
        super(client);
    }

    public Page<Order> list() {
        return list(ListParams.none());
    }

    public Page<Order> list(ListParams params) {
        return page("/orders", Order::from, params.toQuery());
    }

    public PagedIterable<Order> iterate() {
        return iterate(ListParams.none());
    }

    public PagedIterable<Order> iterate(ListParams params) {
        return paginate("/orders", Order::from, params.toQuery(), 100);
    }

    public Order get(String orderId) {
        return one("/orders/" + id(orderId), Order::from, null);
    }

    public Page<Bill> listBills() {
        return listBills(ListParams.none());
    }

    public Page<Bill> listBills(ListParams params) {
        return page("/bills", Bill::from, params.toQuery());
    }

    public PagedIterable<Bill> iterateBills() {
        return iterateBills(ListParams.none());
    }

    public PagedIterable<Bill> iterateBills(ListParams params) {
        return paginate("/bills", Bill::from, params.toQuery(), 50);
    }

    public Bill getBill(String billId) {
        return one("/bills/" + id(billId), Bill::from, null);
    }
}
