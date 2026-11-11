namespace Noosh24.OpenApi;

public static class ReservationStatus
{
    public const string Pending = "pending";
    public const string Confirmed = "confirmed";
    public const string Arriving = "arriving";
    public const string CheckedIn = "checked_in";
    public const string Completed = "completed";
    public const string Cancelled = "cancelled";
    public const string NoShow = "no_show";
}

public static class ReservationSource
{
    public const string Noosh24 = "noosh24";
    public const string OpenApi = "open_api";
}

public static class OrderKind
{
    public const string Table = "table";
    public const string Counter = "counter";
    public const string Delivery = "delivery";
}

public static class OrderStatus
{
    public const string PendingWaiter = "pending_waiter";
    public const string New = "new";
    public const string Accepted = "accepted";
    public const string Preparing = "preparing";
    public const string Ready = "ready";
    public const string Served = "served";
    public const string Cancelled = "cancelled";
}

public static class OrderItemStatus
{
    public const string New = "new";
    public const string Preparing = "preparing";
    public const string Ready = "ready";
    public const string Cancelled = "cancelled";
}

public static class BillStatus
{
    public const string Open = "open";
    public const string BillRequested = "bill_requested";
    public const string Paid = "paid";
    public const string Closed = "closed";
    public const string Abandoned = "abandoned";
    public const string Merged = "merged";
}

public static class PaymentStatus
{
    public const string Pending = "pending";
    public const string RequiresAction = "requires_action";
    public const string Succeeded = "succeeded";
    public const string Failed = "failed";
    public const string Refunded = "refunded";
}

public static class PaymentMethod
{
    public const string Card = "card";
    public const string ApplePay = "apple_pay";
    public const string GooglePay = "google_pay";
    public const string Azqr = "azqr";
    public const string Cash = "cash";
    public const string Birbank = "birbank";
    public const string Platform = "platform";
}

public static class PaymentTakenAt
{
    public const string Till = "till";
    public const string Guest = "guest";
}

public static class TableStatus
{
    public const string Available = "available";
    public const string Reserved = "reserved";
    public const string Occupied = "occupied";
    public const string Cleaning = "cleaning";
    public const string Payment = "payment";
}

public static class LoyaltyProgramEarnBy
{
    public const string Visit = "visit";
    public const string Items = "items";
}

public static class LoyaltyProgramRewardScope
{
    public const string All = "all";
    public const string Categories = "categories";
    public const string Items = "items";
}

public static class LoyaltyCardSource
{
    public const string Panel = "panel";
    public const string Till = "till";
    public const string Web = "web";
    public const string App = "app";
}

public static class IngredientState
{
    public const string Ok = "ok";
    public const string Low = "low";
    public const string Empty = "empty";
}

public static class SubscriptionStatus
{
    public const string None = "none";
    public const string Trial = "trial";
    public const string Active = "active";
    public const string Expiring = "expiring";
    public const string Grace = "grace";
    public const string Restricted = "restricted";
    public const string Suspended = "suspended";
}
