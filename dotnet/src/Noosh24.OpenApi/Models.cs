using System.Text.Json;
using System.Text.Json.Serialization;

namespace Noosh24.OpenApi;

public sealed record Restaurant
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("slug")]
    public string? Slug { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record ApiKeyInfo
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("prefix")]
    public string? Prefix { get; init; }

    [JsonPropertyName("scopes")]
    public IReadOnlyList<string>? Scopes { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record Subscription
{
    [JsonPropertyName("status")]
    public string? Status { get; init; }

    [JsonPropertyName("modules")]
    public IReadOnlyList<string>? Modules { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record Features
{
    [JsonPropertyName("loyalty")]
    public bool? Loyalty { get; init; }

    [JsonPropertyName("inventory")]
    public bool? Inventory { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record Whoami
{
    [JsonPropertyName("restaurant")]
    public Restaurant? Restaurant { get; init; }

    [JsonPropertyName("key")]
    public ApiKeyInfo? Key { get; init; }

    [JsonPropertyName("subscription")]
    public Subscription? Subscription { get; init; }

    [JsonPropertyName("features")]
    public Features? Features { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record Category
{
    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("position")]
    public int? Position { get; init; }

    [JsonPropertyName("products")]
    public int? Products { get; init; }

    [JsonPropertyName("available")]
    public int? Available { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record Modifier
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("priceDelta")]
    public double? PriceDelta { get; init; }

    [JsonPropertyName("position")]
    public int? Position { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record ModifierGroup
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("required")]
    public bool? Required { get; init; }

    [JsonPropertyName("position")]
    public int? Position { get; init; }

    [JsonPropertyName("modifiers")]
    public IReadOnlyList<Modifier>? Modifiers { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record ProductTranslation
{
    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("description")]
    public string? Description { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record Product
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("category")]
    public string? Category { get; init; }

    [JsonPropertyName("description")]
    public string? Description { get; init; }

    [JsonPropertyName("price")]
    public double? Price { get; init; }

    [JsonPropertyName("available")]
    public bool? Available { get; init; }

    [JsonPropertyName("popular")]
    public bool? Popular { get; init; }

    [JsonPropertyName("position")]
    public int? Position { get; init; }

    [JsonPropertyName("prepMinutes")]
    public int? PrepMinutes { get; init; }

    [JsonPropertyName("station")]
    public string? Station { get; init; }

    [JsonPropertyName("vatRate")]
    public double? VatRate { get; init; }

    [JsonPropertyName("vegetarian")]
    public bool? Vegetarian { get; init; }

    [JsonPropertyName("spicy")]
    public bool? Spicy { get; init; }

    [JsonPropertyName("allergens")]
    public IReadOnlyList<string>? Allergens { get; init; }

    [JsonPropertyName("discountable")]
    public bool? Discountable { get; init; }

    [JsonPropertyName("hasModifiers")]
    public bool? HasModifiers { get; init; }

    [JsonPropertyName("image")]
    public string? Image { get; init; }

    [JsonPropertyName("video")]
    public string? Video { get; init; }

    [JsonPropertyName("modifierGroups")]
    public IReadOnlyList<ModifierGroup>? ModifierGroups { get; init; }

    [JsonPropertyName("translations")]
    public IReadOnlyDictionary<string, ProductTranslation>? Translations { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record StopListItem
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("category")]
    public string? Category { get; init; }

    [JsonPropertyName("price")]
    public double? Price { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record ReservationGuest
{
    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("phone")]
    public string? Phone { get; init; }

    [JsonPropertyName("email")]
    public string? Email { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record ReservationTable
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("label")]
    public string? Label { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record ReservationPreOrderItem
{
    [JsonPropertyName("productId")]
    public string? ProductId { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("price")]
    public double? Price { get; init; }

    [JsonPropertyName("qty")]
    public int? Qty { get; init; }

    [JsonPropertyName("note")]
    public string? Note { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record Reservation
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("code")]
    public string? Code { get; init; }

    [JsonPropertyName("status")]
    public string? Status { get; init; }

    [JsonPropertyName("source")]
    public string? Source { get; init; }

    [JsonPropertyName("startsAt")]
    public DateTimeOffset? StartsAt { get; init; }

    [JsonPropertyName("endsAt")]
    public DateTimeOffset? EndsAt { get; init; }

    [JsonPropertyName("guests")]
    public int? Guests { get; init; }

    [JsonPropertyName("zone")]
    public string? Zone { get; init; }

    [JsonPropertyName("table")]
    public ReservationTable? Table { get; init; }

    [JsonPropertyName("guest")]
    public ReservationGuest? Guest { get; init; }

    [JsonPropertyName("specialRequest")]
    public string? SpecialRequest { get; init; }

    [JsonPropertyName("allergyNote")]
    public string? AllergyNote { get; init; }

    [JsonPropertyName("birthday")]
    public bool? Birthday { get; init; }

    [JsonPropertyName("childChair")]
    public bool? ChildChair { get; init; }

    [JsonPropertyName("depositPaid")]
    public double? DepositPaid { get; init; }

    [JsonPropertyName("preOrder")]
    public IReadOnlyList<ReservationPreOrderItem>? PreOrder { get; init; }

    [JsonPropertyName("externalRef")]
    public string? ExternalRef { get; init; }

    [JsonPropertyName("decidedAt")]
    public DateTimeOffset? DecidedAt { get; init; }

    [JsonPropertyName("createdAt")]
    public DateTimeOffset? CreatedAt { get; init; }

    [JsonPropertyName("updatedAt")]
    public DateTimeOffset? UpdatedAt { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record AvailableTable
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("label")]
    public string? Label { get; init; }

    [JsonPropertyName("hallId")]
    public string? HallId { get; init; }

    [JsonPropertyName("zone")]
    public string? Zone { get; init; }

    [JsonPropertyName("seats")]
    public int? Seats { get; init; }

    [JsonPropertyName("free")]
    public bool? Free { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record TableAvailability
{
    [JsonPropertyName("startsAt")]
    public DateTimeOffset? StartsAt { get; init; }

    [JsonPropertyName("endsAt")]
    public DateTimeOffset? EndsAt { get; init; }

    [JsonPropertyName("durationMinutes")]
    public int? DurationMinutes { get; init; }

    [JsonPropertyName("openTime")]
    public string? OpenTime { get; init; }

    [JsonPropertyName("closeTime")]
    public string? CloseTime { get; init; }

    [JsonPropertyName("tables")]
    public IReadOnlyList<AvailableTable>? Tables { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record OrderItem
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("productId")]
    public string? ProductId { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("qty")]
    public int? Qty { get; init; }

    [JsonPropertyName("price")]
    public double? Price { get; init; }

    [JsonPropertyName("listPrice")]
    public double? ListPrice { get; init; }

    [JsonPropertyName("modifiers")]
    public string? Modifiers { get; init; }

    [JsonPropertyName("note")]
    public string? Note { get; init; }

    [JsonPropertyName("status")]
    public string? Status { get; init; }

    [JsonPropertyName("comp")]
    public bool? Comp { get; init; }

    [JsonPropertyName("campaign")]
    public string? Campaign { get; init; }

    [JsonPropertyName("cancelReason")]
    public string? CancelReason { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record DeliveryPlatform
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("ref")]
    public string? Ref { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record OrderDelivery
{
    [JsonPropertyName("status")]
    public string? Status { get; init; }

    [JsonPropertyName("platform")]
    public DeliveryPlatform? Platform { get; init; }

    [JsonPropertyName("address")]
    public string? Address { get; init; }

    [JsonPropertyName("customerPhone")]
    public string? CustomerPhone { get; init; }

    [JsonPropertyName("courierName")]
    public string? CourierName { get; init; }

    [JsonPropertyName("note")]
    public string? Note { get; init; }

    [JsonPropertyName("paymentMethod")]
    public string? PaymentMethod { get; init; }

    [JsonPropertyName("fee")]
    public double? Fee { get; init; }

    [JsonPropertyName("platformTotal")]
    public double? PlatformTotal { get; init; }

    [JsonPropertyName("acceptedAt")]
    public DateTimeOffset? AcceptedAt { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record Order
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("number")]
    public string? Number { get; init; }

    [JsonPropertyName("dailyNumber")]
    public int? DailyNumber { get; init; }

    [JsonPropertyName("kind")]
    public string? Kind { get; init; }

    [JsonPropertyName("orderType")]
    public string? OrderType { get; init; }

    [JsonPropertyName("status")]
    public string? Status { get; init; }

    [JsonPropertyName("tableId")]
    public string? TableId { get; init; }

    [JsonPropertyName("billId")]
    public string? BillId { get; init; }

    [JsonPropertyName("customerName")]
    public string? CustomerName { get; init; }

    [JsonPropertyName("allergyNote")]
    public string? AllergyNote { get; init; }

    [JsonPropertyName("items")]
    public IReadOnlyList<OrderItem>? Items { get; init; }

    [JsonPropertyName("subtotal")]
    public double? Subtotal { get; init; }

    [JsonPropertyName("delivery")]
    public OrderDelivery? Delivery { get; init; }

    [JsonPropertyName("createdAt")]
    public DateTimeOffset? CreatedAt { get; init; }

    [JsonPropertyName("updatedAt")]
    public DateTimeOffset? UpdatedAt { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record Bill
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("tableId")]
    public string? TableId { get; init; }

    [JsonPropertyName("status")]
    public string? Status { get; init; }

    [JsonPropertyName("guests")]
    public int? Guests { get; init; }

    [JsonPropertyName("waiter")]
    public string? Waiter { get; init; }

    [JsonPropertyName("customerId")]
    public string? CustomerId { get; init; }

    [JsonPropertyName("reservationId")]
    public string? ReservationId { get; init; }

    [JsonPropertyName("orderIds")]
    public IReadOnlyList<string>? OrderIds { get; init; }

    [JsonPropertyName("subtotal")]
    public double? Subtotal { get; init; }

    [JsonPropertyName("discountPercent")]
    public double? DiscountPercent { get; init; }

    [JsonPropertyName("billDiscount")]
    public double? BillDiscount { get; init; }

    [JsonPropertyName("serviceFeePercent")]
    public double? ServiceFeePercent { get; init; }

    [JsonPropertyName("serviceFee")]
    public double? ServiceFee { get; init; }

    [JsonPropertyName("total")]
    public double? Total { get; init; }

    [JsonPropertyName("paid")]
    public double? Paid { get; init; }

    [JsonPropertyName("remaining")]
    public double? Remaining { get; init; }

    [JsonPropertyName("openedAt")]
    public DateTimeOffset? OpenedAt { get; init; }

    [JsonPropertyName("closedAt")]
    public DateTimeOffset? ClosedAt { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record PaymentCard
{
    [JsonPropertyName("maskedPan")]
    public string? MaskedPan { get; init; }

    [JsonPropertyName("scheme")]
    public string? Scheme { get; init; }

    [JsonPropertyName("bank")]
    public string? Bank { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record PaymentPlatform
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record Payment
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("status")]
    public string? Status { get; init; }

    [JsonPropertyName("method")]
    public string? Method { get; init; }

    [JsonPropertyName("recordedMethod")]
    public string? RecordedMethod { get; init; }

    [JsonPropertyName("amount")]
    public double? Amount { get; init; }

    [JsonPropertyName("tip")]
    public double? Tip { get; init; }

    [JsonPropertyName("refundedAmount")]
    public double? RefundedAmount { get; init; }

    [JsonPropertyName("refundedAt")]
    public DateTimeOffset? RefundedAt { get; init; }

    [JsonPropertyName("refundReason")]
    public string? RefundReason { get; init; }

    [JsonPropertyName("billId")]
    public string? BillId { get; init; }

    [JsonPropertyName("reservationId")]
    public string? ReservationId { get; init; }

    [JsonPropertyName("orderId")]
    public string? OrderId { get; init; }

    [JsonPropertyName("takenAt")]
    public string? TakenAt { get; init; }

    [JsonPropertyName("card")]
    public PaymentCard? Card { get; init; }

    [JsonPropertyName("platform")]
    public PaymentPlatform? Platform { get; init; }

    [JsonPropertyName("createdAt")]
    public DateTimeOffset? CreatedAt { get; init; }

    [JsonPropertyName("settledAt")]
    public DateTimeOffset? SettledAt { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record Hall
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("position")]
    public int? Position { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record Table
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("label")]
    public string? Label { get; init; }

    [JsonPropertyName("hallId")]
    public string? HallId { get; init; }

    [JsonPropertyName("zone")]
    public string? Zone { get; init; }

    [JsonPropertyName("seats")]
    public int? Seats { get; init; }

    [JsonPropertyName("shape")]
    public string? Shape { get; init; }

    [JsonPropertyName("status")]
    public string? Status { get; init; }

    [JsonPropertyName("guests")]
    public int? Guests { get; init; }

    [JsonPropertyName("waiter")]
    public string? Waiter { get; init; }

    [JsonPropertyName("seatedSince")]
    public string? SeatedSince { get; init; }

    [JsonPropertyName("openOrders")]
    public int? OpenOrders { get; init; }

    [JsonPropertyName("billId")]
    public string? BillId { get; init; }

    [JsonPropertyName("billTotal")]
    public double? BillTotal { get; init; }

    [JsonPropertyName("billRequested")]
    public bool? BillRequested { get; init; }

    [JsonPropertyName("billSettled")]
    public bool? BillSettled { get; init; }

    [JsonPropertyName("mergedInto")]
    public string? MergedInto { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record Customer
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("phone")]
    public string? Phone { get; init; }

    [JsonPropertyName("note")]
    public string? Note { get; init; }

    [JsonPropertyName("createdAt")]
    public DateTimeOffset? CreatedAt { get; init; }

    [JsonPropertyName("updatedAt")]
    public DateTimeOffset? UpdatedAt { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record LoyaltyProgram
{
    [JsonPropertyName("stampsNeeded")]
    public int? StampsNeeded { get; init; }

    [JsonPropertyName("earnBy")]
    public string? EarnBy { get; init; }

    [JsonPropertyName("minBill")]
    public double? MinBill { get; init; }

    [JsonPropertyName("oncePerDay")]
    public bool? OncePerDay { get; init; }

    [JsonPropertyName("rewardName")]
    public string? RewardName { get; init; }

    [JsonPropertyName("rewardScope")]
    public string? RewardScope { get; init; }

    [JsonPropertyName("rewardCategories")]
    public IReadOnlyList<string>? RewardCategories { get; init; }

    [JsonPropertyName("rewardProductIds")]
    public IReadOnlyList<string>? RewardProductIds { get; init; }

    [JsonPropertyName("rewardMaxPrice")]
    public double? RewardMaxPrice { get; init; }

    [JsonPropertyName("terms")]
    public string? Terms { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record LoyaltyCard
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("phone")]
    public string? Phone { get; init; }

    [JsonPropertyName("stamps")]
    public int? Stamps { get; init; }

    [JsonPropertyName("totalStamps")]
    public int? TotalStamps { get; init; }

    [JsonPropertyName("redeemed")]
    public int? Redeemed { get; init; }

    [JsonPropertyName("source")]
    public string? Source { get; init; }

    [JsonPropertyName("lastVisitAt")]
    public DateTimeOffset? LastVisitAt { get; init; }

    [JsonPropertyName("createdAt")]
    public DateTimeOffset? CreatedAt { get; init; }

    [JsonPropertyName("updatedAt")]
    public DateTimeOffset? UpdatedAt { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record Ingredient
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("unit")]
    public string? Unit { get; init; }

    [JsonPropertyName("stock")]
    public double? Stock { get; init; }

    [JsonPropertyName("onOpenBills")]
    public double? OnOpenBills { get; init; }

    [JsonPropertyName("available")]
    public double? Available { get; init; }

    [JsonPropertyName("state")]
    public string? State { get; init; }

    [JsonPropertyName("lowStock")]
    public double? LowStock { get; init; }

    [JsonPropertyName("parStock")]
    public double? ParStock { get; init; }

    [JsonPropertyName("costPerUnit")]
    public double? CostPerUnit { get; init; }

    [JsonPropertyName("value")]
    public double? Value { get; init; }

    [JsonPropertyName("prepared")]
    public bool? Prepared { get; init; }

    [JsonPropertyName("byStore")]
    public IReadOnlyDictionary<string, double>? ByStore { get; init; }

    [JsonPropertyName("updatedAt")]
    public DateTimeOffset? UpdatedAt { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record StockStore
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("name")]
    public string? Name { get; init; }

    [JsonPropertyName("isDefault")]
    public bool? IsDefault { get; init; }

    [JsonPropertyName("stations")]
    public IReadOnlyList<string>? Stations { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record StockMove
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("ingredientId")]
    public string? IngredientId { get; init; }

    [JsonPropertyName("qty")]
    public double? Qty { get; init; }

    [JsonPropertyName("reason")]
    public string? Reason { get; init; }

    [JsonPropertyName("orderId")]
    public string? OrderId { get; init; }

    [JsonPropertyName("invoiceId")]
    public string? InvoiceId { get; init; }

    [JsonPropertyName("storeId")]
    public string? StoreId { get; init; }

    [JsonPropertyName("note")]
    public string? Note { get; init; }

    [JsonPropertyName("createdAt")]
    public DateTimeOffset? CreatedAt { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record ReviewRatings
{
    [JsonPropertyName("food")]
    public double? Food { get; init; }

    [JsonPropertyName("service")]
    public double? Service { get; init; }

    [JsonPropertyName("atmosphere")]
    public double? Atmosphere { get; init; }

    [JsonPropertyName("cleanliness")]
    public double? Cleanliness { get; init; }

    [JsonPropertyName("price")]
    public double? Price { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}

public sealed record Review
{
    [JsonPropertyName("id")]
    public string? Id { get; init; }

    [JsonPropertyName("author")]
    public string? Author { get; init; }

    [JsonPropertyName("overall")]
    public double? Overall { get; init; }

    [JsonPropertyName("ratings")]
    public ReviewRatings? Ratings { get; init; }

    [JsonPropertyName("body")]
    public string? Body { get; init; }

    [JsonPropertyName("visitType")]
    public string? VisitType { get; init; }

    [JsonPropertyName("visitedOn")]
    public DateTimeOffset? VisitedOn { get; init; }

    [JsonPropertyName("verified")]
    public bool? Verified { get; init; }

    [JsonPropertyName("reply")]
    public string? Reply { get; init; }

    [JsonPropertyName("repliedAt")]
    public DateTimeOffset? RepliedAt { get; init; }

    [JsonPropertyName("createdAt")]
    public DateTimeOffset? CreatedAt { get; init; }

    [JsonExtensionData]
    [JsonInclude]
    public IDictionary<string, JsonElement>? ExtensionData { get; internal set; }
}
