package com.noosh24.openapi;

import com.noosh24.openapi.model.LoyaltyCard;
import com.noosh24.openapi.model.LoyaltyProgram;

public final class Loyalty extends Resource {
    Loyalty(Noosh24Client client) {
        super(client);
    }

    public LoyaltyProgram getProgram() {
        return one("/loyalty/program", LoyaltyProgram::from, null);
    }

    public Page<LoyaltyCard> listCards() {
        return listCards(ListParams.none());
    }

    public Page<LoyaltyCard> listCards(ListParams params) {
        return page("/loyalty/cards", LoyaltyCard::from, params.toQuery());
    }

    public PagedIterable<LoyaltyCard> iterateCards() {
        return iterateCards(ListParams.none());
    }

    public PagedIterable<LoyaltyCard> iterateCards(ListParams params) {
        return paginate("/loyalty/cards", LoyaltyCard::from, params.toQuery(), 100);
    }
}
