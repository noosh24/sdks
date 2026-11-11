package com.noosh24.openapi;

import com.noosh24.openapi.model.Category;
import com.noosh24.openapi.model.Product;
import com.noosh24.openapi.model.StopListItem;
import java.util.Arrays;
import java.util.List;

public final class Menu extends Resource {
    Menu(Noosh24Client client) {
        super(client);
    }

    public List<Category> listCategories() {
        return all("/menu/categories", Category::from);
    }

    public Page<Product> listProducts() {
        return listProducts(ProductListParams.none());
    }

    public Page<Product> listProducts(ProductListParams params) {
        return page("/menu/products", Product::from, params.toQuery());
    }

    public PagedIterable<Product> iterateProducts() {
        return iterateProducts(ProductListParams.none());
    }

    public PagedIterable<Product> iterateProducts(ProductListParams params) {
        return paginate("/menu/products", Product::from, params.toQuery(), params.expand().isEmpty() ? 100 : 50);
    }

    public Product getProduct(String productId, ProductExpand... expand) {
        return getProduct(productId, Arrays.asList(expand));
    }

    public Product getProduct(String productId, List<ProductExpand> expand) {
        Query query = new Query();
        if (!expand.isEmpty()) {
            query.add("expand", ProductListParams.expandValues(expand));
        }
        return one("/menu/products/" + id(productId), Product::from, query);
    }

    public List<StopListItem> getStopList() {
        return all("/menu/stop-list", StopListItem::from);
    }
}
