package com.noosh24.openapi.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.util.List;
import org.jspecify.annotations.Nullable;
import tools.jackson.databind.JsonNode;

@JsonIgnoreProperties(ignoreUnknown = true)
public record LoyaltyProgram(
        @Nullable Integer stampsNeeded,
        @Nullable String earnBy,
        @Nullable Double minBill,
        @Nullable Boolean oncePerDay,
        @Nullable String rewardName,
        @Nullable String rewardScope,
        List<String> rewardCategories,
        List<String> rewardProductIds,
        @Nullable Double rewardMaxPrice,
        @Nullable String terms,
        @JsonIgnore @Nullable JsonNode raw) {

    public LoyaltyProgram {
        rewardCategories = Fields.copy(rewardCategories);
        rewardProductIds = Fields.copy(rewardProductIds);
    }

    public static LoyaltyProgram from(@Nullable JsonNode node) {
        JsonNode n = Fields.object(node);
        return new LoyaltyProgram(
                Fields.integer(n, "stampsNeeded"),
                Fields.string(n, "earnBy"),
                Fields.number(n, "minBill"),
                Fields.bool(n, "oncePerDay"),
                Fields.string(n, "rewardName"),
                Fields.string(n, "rewardScope"),
                Fields.strings(n, "rewardCategories"),
                Fields.strings(n, "rewardProductIds"),
                Fields.number(n, "rewardMaxPrice"),
                Fields.string(n, "terms"),
                n);
    }
}
