package com.noosh24.openapi;

import com.noosh24.openapi.model.Ingredient;
import com.noosh24.openapi.model.StockMove;
import com.noosh24.openapi.model.StockStore;
import java.util.List;

public final class Stock extends Resource {
    Stock(Noosh24Client client) {
        super(client);
    }

    public Page<Ingredient> listIngredients() {
        return listIngredients(ListParams.none());
    }

    public Page<Ingredient> listIngredients(ListParams params) {
        return page("/stock/ingredients", Ingredient::from, params.toQuery());
    }

    public PagedIterable<Ingredient> iterateIngredients() {
        return iterateIngredients(ListParams.none());
    }

    public PagedIterable<Ingredient> iterateIngredients(ListParams params) {
        return paginate("/stock/ingredients", Ingredient::from, params.toQuery(), 100);
    }

    public Page<StockMove> listMoves() {
        return listMoves(ListParams.none());
    }

    public Page<StockMove> listMoves(ListParams params) {
        return page("/stock/moves", StockMove::from, params.toQuery());
    }

    public PagedIterable<StockMove> iterateMoves() {
        return iterateMoves(ListParams.none());
    }

    public PagedIterable<StockMove> iterateMoves(ListParams params) {
        return paginate("/stock/moves", StockMove::from, params.toQuery(), 100);
    }

    public List<StockStore> listStores() {
        return all("/stock/stores", StockStore::from);
    }
}
