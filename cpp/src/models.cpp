#include "noosh24/models.hpp"

#include "internal.hpp"

namespace noosh24 {

Restaurant Restaurant::from_json(const nlohmann::json& data)
{
    Restaurant out;
    out.id = detail::read_string(data, "id");
    out.name = detail::read_string(data, "name");
    out.slug = detail::read_string(data, "slug");
    out.raw = data;
    return out;
}

ApiKeyInfo ApiKeyInfo::from_json(const nlohmann::json& data)
{
    ApiKeyInfo out;
    out.id = detail::read_string(data, "id");
    out.name = detail::read_string(data, "name");
    out.prefix = detail::read_string(data, "prefix");
    out.scopes = detail::read_strings(data, "scopes");
    out.raw = data;
    return out;
}

Subscription Subscription::from_json(const nlohmann::json& data)
{
    Subscription out;
    out.status = detail::read_string(data, "status");
    out.modules = detail::read_strings(data, "modules");
    out.raw = data;
    return out;
}

Features Features::from_json(const nlohmann::json& data)
{
    Features out;
    out.loyalty = detail::read_bool(data, "loyalty");
    out.inventory = detail::read_bool(data, "inventory");
    out.raw = data;
    return out;
}

Whoami Whoami::from_json(const nlohmann::json& data)
{
    Whoami out;
    out.restaurant = detail::read_object<Restaurant>(data, "restaurant");
    out.key = detail::read_object<ApiKeyInfo>(data, "key");
    out.subscription = detail::read_object<Subscription>(data, "subscription");
    out.features = detail::read_object<Features>(data, "features");
    out.raw = data;
    return out;
}

Category Category::from_json(const nlohmann::json& data)
{
    Category out;
    out.name = detail::read_string(data, "name");
    out.position = detail::read_int(data, "position");
    out.products = detail::read_int(data, "products");
    out.available = detail::read_int(data, "available");
    out.raw = data;
    return out;
}

Modifier Modifier::from_json(const nlohmann::json& data)
{
    Modifier out;
    out.id = detail::read_string(data, "id");
    out.name = detail::read_string(data, "name");
    out.price_delta = detail::read_double(data, "priceDelta");
    out.position = detail::read_int(data, "position");
    out.raw = data;
    return out;
}

ModifierGroup ModifierGroup::from_json(const nlohmann::json& data)
{
    ModifierGroup out;
    out.id = detail::read_string(data, "id");
    out.name = detail::read_string(data, "name");
    out.required = detail::read_bool(data, "required");
    out.position = detail::read_int(data, "position");
    out.modifiers = detail::read_list<Modifier>(data, "modifiers");
    out.raw = data;
    return out;
}

ProductTranslation ProductTranslation::from_json(const nlohmann::json& data)
{
    ProductTranslation out;
    out.name = detail::read_string(data, "name");
    out.description = detail::read_string(data, "description");
    out.raw = data;
    return out;
}

Product Product::from_json(const nlohmann::json& data)
{
    Product out;
    out.id = detail::read_string(data, "id");
    out.name = detail::read_string(data, "name");
    out.category = detail::read_string(data, "category");
    out.description = detail::read_string(data, "description");
    out.price = detail::read_double(data, "price");
    out.available = detail::read_bool(data, "available");
    out.popular = detail::read_bool(data, "popular");
    out.position = detail::read_int(data, "position");
    out.prep_minutes = detail::read_int(data, "prepMinutes");
    out.station = detail::read_string(data, "station");
    out.vat_rate = detail::read_double(data, "vatRate");
    out.vegetarian = detail::read_bool(data, "vegetarian");
    out.spicy = detail::read_bool(data, "spicy");
    out.allergens = detail::read_strings(data, "allergens");
    out.discountable = detail::read_bool(data, "discountable");
    out.has_modifiers = detail::read_bool(data, "hasModifiers");
    out.image = detail::read_string(data, "image");
    out.video = detail::read_string(data, "video");
    out.modifier_groups = detail::read_list<ModifierGroup>(data, "modifierGroups");
    out.translations = detail::read_map<ProductTranslation>(data, "translations");
    out.raw = data;
    return out;
}

StopListItem StopListItem::from_json(const nlohmann::json& data)
{
    StopListItem out;
    out.id = detail::read_string(data, "id");
    out.name = detail::read_string(data, "name");
    out.category = detail::read_string(data, "category");
    out.price = detail::read_double(data, "price");
    out.raw = data;
    return out;
}

ReservationGuest ReservationGuest::from_json(const nlohmann::json& data)
{
    ReservationGuest out;
    out.name = detail::read_string(data, "name");
    out.phone = detail::read_string(data, "phone");
    out.email = detail::read_string(data, "email");
    out.raw = data;
    return out;
}

ReservationTable ReservationTable::from_json(const nlohmann::json& data)
{
    ReservationTable out;
    out.id = detail::read_string(data, "id");
    out.label = detail::read_string(data, "label");
    out.raw = data;
    return out;
}

ReservationPreOrderItem ReservationPreOrderItem::from_json(const nlohmann::json& data)
{
    ReservationPreOrderItem out;
    out.product_id = detail::read_string(data, "productId");
    out.name = detail::read_string(data, "name");
    out.price = detail::read_double(data, "price");
    out.qty = detail::read_int(data, "qty");
    out.note = detail::read_string(data, "note");
    out.raw = data;
    return out;
}

Reservation Reservation::from_json(const nlohmann::json& data)
{
    Reservation out;
    out.id = detail::read_string(data, "id");
    out.code = detail::read_string(data, "code");
    out.status = detail::read_string(data, "status");
    out.source = detail::read_string(data, "source");
    out.starts_at = detail::read_timestamp(data, "startsAt");
    out.ends_at = detail::read_timestamp(data, "endsAt");
    out.guests = detail::read_int(data, "guests");
    out.zone = detail::read_string(data, "zone");
    out.table = detail::read_object<ReservationTable>(data, "table");
    out.guest = detail::read_object<ReservationGuest>(data, "guest");
    out.special_request = detail::read_string(data, "specialRequest");
    out.allergy_note = detail::read_string(data, "allergyNote");
    out.birthday = detail::read_bool(data, "birthday");
    out.child_chair = detail::read_bool(data, "childChair");
    out.deposit_paid = detail::read_double(data, "depositPaid");
    out.pre_order = detail::read_list<ReservationPreOrderItem>(data, "preOrder");
    out.external_ref = detail::read_string(data, "externalRef");
    out.decided_at = detail::read_timestamp(data, "decidedAt");
    out.created_at = detail::read_timestamp(data, "createdAt");
    out.updated_at = detail::read_timestamp(data, "updatedAt");
    out.raw = data;
    return out;
}

AvailableTable AvailableTable::from_json(const nlohmann::json& data)
{
    AvailableTable out;
    out.id = detail::read_string(data, "id");
    out.label = detail::read_string(data, "label");
    out.hall_id = detail::read_string(data, "hallId");
    out.zone = detail::read_string(data, "zone");
    out.seats = detail::read_int(data, "seats");
    out.free = detail::read_bool(data, "free");
    out.raw = data;
    return out;
}

TableAvailability TableAvailability::from_json(const nlohmann::json& data)
{
    TableAvailability out;
    out.starts_at = detail::read_timestamp(data, "startsAt");
    out.ends_at = detail::read_timestamp(data, "endsAt");
    out.duration_minutes = detail::read_int(data, "durationMinutes");
    out.open_time = detail::read_string(data, "openTime");
    out.close_time = detail::read_string(data, "closeTime");
    out.tables = detail::read_list<AvailableTable>(data, "tables");
    out.raw = data;
    return out;
}

OrderItem OrderItem::from_json(const nlohmann::json& data)
{
    OrderItem out;
    out.id = detail::read_string(data, "id");
    out.product_id = detail::read_string(data, "productId");
    out.name = detail::read_string(data, "name");
    out.qty = detail::read_int(data, "qty");
    out.price = detail::read_double(data, "price");
    out.list_price = detail::read_double(data, "listPrice");
    out.modifiers = detail::read_string(data, "modifiers");
    out.note = detail::read_string(data, "note");
    out.status = detail::read_string(data, "status");
    out.comp = detail::read_bool(data, "comp");
    out.campaign = detail::read_string(data, "campaign");
    out.cancel_reason = detail::read_string(data, "cancelReason");
    out.raw = data;
    return out;
}

DeliveryPlatform DeliveryPlatform::from_json(const nlohmann::json& data)
{
    DeliveryPlatform out;
    out.id = detail::read_string(data, "id");
    out.name = detail::read_string(data, "name");
    out.ref = detail::read_string(data, "ref");
    out.raw = data;
    return out;
}

OrderDelivery OrderDelivery::from_json(const nlohmann::json& data)
{
    OrderDelivery out;
    out.status = detail::read_string(data, "status");
    out.platform = detail::read_object<DeliveryPlatform>(data, "platform");
    out.address = detail::read_string(data, "address");
    out.customer_phone = detail::read_string(data, "customerPhone");
    out.courier_name = detail::read_string(data, "courierName");
    out.note = detail::read_string(data, "note");
    out.payment_method = detail::read_string(data, "paymentMethod");
    out.fee = detail::read_double(data, "fee");
    out.platform_total = detail::read_double(data, "platformTotal");
    out.accepted_at = detail::read_timestamp(data, "acceptedAt");
    out.raw = data;
    return out;
}

Order Order::from_json(const nlohmann::json& data)
{
    Order out;
    out.id = detail::read_string(data, "id");
    out.number = detail::read_string(data, "number");
    out.daily_number = detail::read_int(data, "dailyNumber");
    out.kind = detail::read_string(data, "kind");
    out.order_type = detail::read_string(data, "orderType");
    out.status = detail::read_string(data, "status");
    out.table_id = detail::read_string(data, "tableId");
    out.bill_id = detail::read_string(data, "billId");
    out.customer_name = detail::read_string(data, "customerName");
    out.allergy_note = detail::read_string(data, "allergyNote");
    out.items = detail::read_list<OrderItem>(data, "items");
    out.subtotal = detail::read_double(data, "subtotal");
    out.delivery = detail::read_object<OrderDelivery>(data, "delivery");
    out.created_at = detail::read_timestamp(data, "createdAt");
    out.updated_at = detail::read_timestamp(data, "updatedAt");
    out.raw = data;
    return out;
}

Bill Bill::from_json(const nlohmann::json& data)
{
    Bill out;
    out.id = detail::read_string(data, "id");
    out.table_id = detail::read_string(data, "tableId");
    out.status = detail::read_string(data, "status");
    out.guests = detail::read_int(data, "guests");
    out.waiter = detail::read_string(data, "waiter");
    out.customer_id = detail::read_string(data, "customerId");
    out.reservation_id = detail::read_string(data, "reservationId");
    out.order_ids = detail::read_strings(data, "orderIds");
    out.subtotal = detail::read_double(data, "subtotal");
    out.discount_percent = detail::read_double(data, "discountPercent");
    out.bill_discount = detail::read_double(data, "billDiscount");
    out.service_fee_percent = detail::read_double(data, "serviceFeePercent");
    out.service_fee = detail::read_double(data, "serviceFee");
    out.total = detail::read_double(data, "total");
    out.paid = detail::read_double(data, "paid");
    out.remaining = detail::read_double(data, "remaining");
    out.opened_at = detail::read_timestamp(data, "openedAt");
    out.closed_at = detail::read_timestamp(data, "closedAt");
    out.raw = data;
    return out;
}

PaymentCard PaymentCard::from_json(const nlohmann::json& data)
{
    PaymentCard out;
    out.masked_pan = detail::read_string(data, "maskedPan");
    out.scheme = detail::read_string(data, "scheme");
    out.bank = detail::read_string(data, "bank");
    out.raw = data;
    return out;
}

PaymentPlatform PaymentPlatform::from_json(const nlohmann::json& data)
{
    PaymentPlatform out;
    out.id = detail::read_string(data, "id");
    out.name = detail::read_string(data, "name");
    out.raw = data;
    return out;
}

Payment Payment::from_json(const nlohmann::json& data)
{
    Payment out;
    out.id = detail::read_string(data, "id");
    out.status = detail::read_string(data, "status");
    out.method = detail::read_string(data, "method");
    out.recorded_method = detail::read_string(data, "recordedMethod");
    out.amount = detail::read_double(data, "amount");
    out.tip = detail::read_double(data, "tip");
    out.refunded_amount = detail::read_double(data, "refundedAmount");
    out.refunded_at = detail::read_timestamp(data, "refundedAt");
    out.refund_reason = detail::read_string(data, "refundReason");
    out.bill_id = detail::read_string(data, "billId");
    out.reservation_id = detail::read_string(data, "reservationId");
    out.order_id = detail::read_string(data, "orderId");
    out.taken_at = detail::read_string(data, "takenAt");
    out.card = detail::read_object<PaymentCard>(data, "card");
    out.platform = detail::read_object<PaymentPlatform>(data, "platform");
    out.created_at = detail::read_timestamp(data, "createdAt");
    out.settled_at = detail::read_timestamp(data, "settledAt");
    out.raw = data;
    return out;
}

Hall Hall::from_json(const nlohmann::json& data)
{
    Hall out;
    out.id = detail::read_string(data, "id");
    out.name = detail::read_string(data, "name");
    out.position = detail::read_int(data, "position");
    out.raw = data;
    return out;
}

Table Table::from_json(const nlohmann::json& data)
{
    Table out;
    out.id = detail::read_string(data, "id");
    out.label = detail::read_string(data, "label");
    out.hall_id = detail::read_string(data, "hallId");
    out.zone = detail::read_string(data, "zone");
    out.seats = detail::read_int(data, "seats");
    out.shape = detail::read_string(data, "shape");
    out.status = detail::read_string(data, "status");
    out.guests = detail::read_int(data, "guests");
    out.waiter = detail::read_string(data, "waiter");
    out.seated_since = detail::read_string(data, "seatedSince");
    out.open_orders = detail::read_int(data, "openOrders");
    out.bill_id = detail::read_string(data, "billId");
    out.bill_total = detail::read_double(data, "billTotal");
    out.bill_requested = detail::read_bool(data, "billRequested");
    out.bill_settled = detail::read_bool(data, "billSettled");
    out.merged_into = detail::read_string(data, "mergedInto");
    out.raw = data;
    return out;
}

Customer Customer::from_json(const nlohmann::json& data)
{
    Customer out;
    out.id = detail::read_string(data, "id");
    out.name = detail::read_string(data, "name");
    out.phone = detail::read_string(data, "phone");
    out.note = detail::read_string(data, "note");
    out.created_at = detail::read_timestamp(data, "createdAt");
    out.updated_at = detail::read_timestamp(data, "updatedAt");
    out.raw = data;
    return out;
}

LoyaltyProgram LoyaltyProgram::from_json(const nlohmann::json& data)
{
    LoyaltyProgram out;
    out.stamps_needed = detail::read_int(data, "stampsNeeded");
    out.earn_by = detail::read_string(data, "earnBy");
    out.min_bill = detail::read_double(data, "minBill");
    out.once_per_day = detail::read_bool(data, "oncePerDay");
    out.reward_name = detail::read_string(data, "rewardName");
    out.reward_scope = detail::read_string(data, "rewardScope");
    out.reward_categories = detail::read_strings(data, "rewardCategories");
    out.reward_product_ids = detail::read_strings(data, "rewardProductIds");
    out.reward_max_price = detail::read_double(data, "rewardMaxPrice");
    out.terms = detail::read_string(data, "terms");
    out.raw = data;
    return out;
}

LoyaltyCard LoyaltyCard::from_json(const nlohmann::json& data)
{
    LoyaltyCard out;
    out.id = detail::read_string(data, "id");
    out.name = detail::read_string(data, "name");
    out.phone = detail::read_string(data, "phone");
    out.stamps = detail::read_int(data, "stamps");
    out.total_stamps = detail::read_int(data, "totalStamps");
    out.redeemed = detail::read_int(data, "redeemed");
    out.source = detail::read_string(data, "source");
    out.last_visit_at = detail::read_timestamp(data, "lastVisitAt");
    out.created_at = detail::read_timestamp(data, "createdAt");
    out.updated_at = detail::read_timestamp(data, "updatedAt");
    out.raw = data;
    return out;
}

Ingredient Ingredient::from_json(const nlohmann::json& data)
{
    Ingredient out;
    out.id = detail::read_string(data, "id");
    out.name = detail::read_string(data, "name");
    out.unit = detail::read_string(data, "unit");
    out.stock = detail::read_double(data, "stock");
    out.on_open_bills = detail::read_double(data, "onOpenBills");
    out.available = detail::read_double(data, "available");
    out.state = detail::read_string(data, "state");
    out.low_stock = detail::read_double(data, "lowStock");
    out.par_stock = detail::read_double(data, "parStock");
    out.cost_per_unit = detail::read_double(data, "costPerUnit");
    out.value = detail::read_double(data, "value");
    out.prepared = detail::read_bool(data, "prepared");
    out.by_store = detail::read_doubles(data, "byStore");
    out.updated_at = detail::read_timestamp(data, "updatedAt");
    out.raw = data;
    return out;
}

StockStore StockStore::from_json(const nlohmann::json& data)
{
    StockStore out;
    out.id = detail::read_string(data, "id");
    out.name = detail::read_string(data, "name");
    out.is_default = detail::read_bool(data, "isDefault");
    out.stations = detail::read_strings(data, "stations");
    out.raw = data;
    return out;
}

StockMove StockMove::from_json(const nlohmann::json& data)
{
    StockMove out;
    out.id = detail::read_string(data, "id");
    out.ingredient_id = detail::read_string(data, "ingredientId");
    out.qty = detail::read_double(data, "qty");
    out.reason = detail::read_string(data, "reason");
    out.order_id = detail::read_string(data, "orderId");
    out.invoice_id = detail::read_string(data, "invoiceId");
    out.store_id = detail::read_string(data, "storeId");
    out.note = detail::read_string(data, "note");
    out.created_at = detail::read_timestamp(data, "createdAt");
    out.raw = data;
    return out;
}

ReviewRatings ReviewRatings::from_json(const nlohmann::json& data)
{
    ReviewRatings out;
    out.food = detail::read_double(data, "food");
    out.service = detail::read_double(data, "service");
    out.atmosphere = detail::read_double(data, "atmosphere");
    out.cleanliness = detail::read_double(data, "cleanliness");
    out.price = detail::read_double(data, "price");
    out.raw = data;
    return out;
}

Review Review::from_json(const nlohmann::json& data)
{
    Review out;
    out.id = detail::read_string(data, "id");
    out.author = detail::read_string(data, "author");
    out.overall = detail::read_double(data, "overall");
    out.ratings = detail::read_object<ReviewRatings>(data, "ratings");
    out.body = detail::read_string(data, "body");
    out.visit_type = detail::read_string(data, "visitType");
    out.visited_on = detail::read_timestamp(data, "visitedOn");
    out.verified = detail::read_bool(data, "verified");
    out.reply = detail::read_string(data, "reply");
    out.replied_at = detail::read_timestamp(data, "repliedAt");
    out.created_at = detail::read_timestamp(data, "createdAt");
    out.raw = data;
    return out;
}

}
