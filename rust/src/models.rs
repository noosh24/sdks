use std::collections::HashMap;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

use crate::de;

string_enum! {
    ReservationStatus {
        Pending => "pending",
        Confirmed => "confirmed",
        Arriving => "arriving",
        CheckedIn => "checked_in",
        Completed => "completed",
        Cancelled => "cancelled",
        NoShow => "no_show",
    }
}

string_enum! {
    ReservationSource {
        Noosh24 => "noosh24",
        OpenApi => "open_api",
    }
}

string_enum! {
    OrderKind {
        Table => "table",
        Counter => "counter",
        Delivery => "delivery",
    }
}

string_enum! {
    OrderStatus {
        PendingWaiter => "pending_waiter",
        New => "new",
        Accepted => "accepted",
        Preparing => "preparing",
        Ready => "ready",
        Served => "served",
        Cancelled => "cancelled",
    }
}

string_enum! {
    OrderItemStatus {
        New => "new",
        Preparing => "preparing",
        Ready => "ready",
        Cancelled => "cancelled",
    }
}

string_enum! {
    BillStatus {
        Open => "open",
        BillRequested => "bill_requested",
        Paid => "paid",
        Closed => "closed",
        Abandoned => "abandoned",
        Merged => "merged",
    }
}

string_enum! {
    PaymentStatus {
        Pending => "pending",
        RequiresAction => "requires_action",
        Succeeded => "succeeded",
        Failed => "failed",
        Refunded => "refunded",
    }
}

string_enum! {
    PaymentMethod {
        Card => "card",
        ApplePay => "apple_pay",
        GooglePay => "google_pay",
        Azqr => "azqr",
        Cash => "cash",
        Birbank => "birbank",
        Platform => "platform",
    }
}

string_enum! {
    PaymentTakenAt {
        Till => "till",
        Guest => "guest",
    }
}

string_enum! {
    TableStatus {
        Available => "available",
        Reserved => "reserved",
        Occupied => "occupied",
        Cleaning => "cleaning",
        Payment => "payment",
    }
}

string_enum! {
    LoyaltyProgramEarnBy {
        Visit => "visit",
        Items => "items",
    }
}

string_enum! {
    LoyaltyProgramRewardScope {
        All => "all",
        Categories => "categories",
        Items => "items",
    }
}

string_enum! {
    LoyaltyCardSource {
        Panel => "panel",
        Till => "till",
        Web => "web",
        App => "app",
    }
}

string_enum! {
    IngredientState {
        Ok => "ok",
        Low => "low",
        Empty => "empty",
    }
}

string_enum! {
    SubscriptionStatus {
        None => "none",
        Trial => "trial",
        Active => "active",
        Expiring => "expiring",
        Grace => "grace",
        Restricted => "restricted",
        Suspended => "suspended",
    }
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Restaurant {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub slug: Option<String>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct ApiKeyInfo {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub prefix: Option<String>,
    #[serde(default, deserialize_with = "de::strings", skip_serializing_if = "Vec::is_empty")]
    pub scopes: Vec<String>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Subscription {
    #[serde(
        default,
        deserialize_with = "de::enumeration",
        skip_serializing_if = "Option::is_none"
    )]
    pub status: Option<SubscriptionStatus>,
    #[serde(default, deserialize_with = "de::strings", skip_serializing_if = "Vec::is_empty")]
    pub modules: Vec<String>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Features {
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub loyalty: Option<bool>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub inventory: Option<bool>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Whoami {
    #[serde(default, deserialize_with = "de::model", skip_serializing_if = "Option::is_none")]
    pub restaurant: Option<Restaurant>,
    #[serde(default, deserialize_with = "de::model", skip_serializing_if = "Option::is_none")]
    pub key: Option<ApiKeyInfo>,
    #[serde(default, deserialize_with = "de::model", skip_serializing_if = "Option::is_none")]
    pub subscription: Option<Subscription>,
    #[serde(default, deserialize_with = "de::model", skip_serializing_if = "Option::is_none")]
    pub features: Option<Features>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Category {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub position: Option<i64>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub products: Option<i64>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub available: Option<i64>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Modifier {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub price_delta: Option<f64>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub position: Option<i64>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct ModifierGroup {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub required: Option<bool>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub position: Option<i64>,
    #[serde(default, deserialize_with = "de::models", skip_serializing_if = "Vec::is_empty")]
    pub modifiers: Vec<Modifier>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct ProductTranslation {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Product {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub category: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub price: Option<f64>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub available: Option<bool>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub popular: Option<bool>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub position: Option<i64>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub prep_minutes: Option<i64>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub station: Option<String>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub vat_rate: Option<f64>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub vegetarian: Option<bool>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub spicy: Option<bool>,
    #[serde(default, deserialize_with = "de::strings", skip_serializing_if = "Vec::is_empty")]
    pub allergens: Vec<String>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub discountable: Option<bool>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub has_modifiers: Option<bool>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub image: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub video: Option<String>,
    #[serde(default, deserialize_with = "de::models", skip_serializing_if = "Vec::is_empty")]
    pub modifier_groups: Vec<ModifierGroup>,
    #[serde(
        default,
        deserialize_with = "de::model_map",
        skip_serializing_if = "HashMap::is_empty"
    )]
    pub translations: HashMap<String, ProductTranslation>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct StopListItem {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub category: Option<String>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub price: Option<f64>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct ReservationGuest {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub phone: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub email: Option<String>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct ReservationTable {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub label: Option<String>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct ReservationPreOrderItem {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub product_id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub price: Option<f64>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub qty: Option<i64>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Reservation {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub code: Option<String>,
    #[serde(
        default,
        deserialize_with = "de::enumeration",
        skip_serializing_if = "Option::is_none"
    )]
    pub status: Option<ReservationStatus>,
    #[serde(
        default,
        deserialize_with = "de::enumeration",
        skip_serializing_if = "Option::is_none"
    )]
    pub source: Option<ReservationSource>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub starts_at: Option<DateTime<Utc>>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub ends_at: Option<DateTime<Utc>>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub guests: Option<i64>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub zone: Option<String>,
    #[serde(default, deserialize_with = "de::model", skip_serializing_if = "Option::is_none")]
    pub table: Option<ReservationTable>,
    #[serde(default, deserialize_with = "de::model", skip_serializing_if = "Option::is_none")]
    pub guest: Option<ReservationGuest>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub special_request: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub allergy_note: Option<String>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub birthday: Option<bool>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub child_chair: Option<bool>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub deposit_paid: Option<f64>,
    #[serde(default, deserialize_with = "de::models", skip_serializing_if = "Vec::is_empty")]
    pub pre_order: Vec<ReservationPreOrderItem>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub external_ref: Option<String>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub decided_at: Option<DateTime<Utc>>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub created_at: Option<DateTime<Utc>>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub updated_at: Option<DateTime<Utc>>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct AvailableTable {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub label: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub hall_id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub zone: Option<String>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub seats: Option<i64>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub free: Option<bool>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct TableAvailability {
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub starts_at: Option<DateTime<Utc>>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub ends_at: Option<DateTime<Utc>>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub duration_minutes: Option<i64>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub open_time: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub close_time: Option<String>,
    #[serde(default, deserialize_with = "de::models", skip_serializing_if = "Vec::is_empty")]
    pub tables: Vec<AvailableTable>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct OrderItem {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub product_id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub qty: Option<i64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub price: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub list_price: Option<f64>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub modifiers: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
    #[serde(
        default,
        deserialize_with = "de::enumeration",
        skip_serializing_if = "Option::is_none"
    )]
    pub status: Option<OrderItemStatus>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub comp: Option<bool>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub campaign: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub cancel_reason: Option<String>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct DeliveryPlatform {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(
        rename = "ref",
        default,
        deserialize_with = "de::string",
        skip_serializing_if = "Option::is_none"
    )]
    pub reference: Option<String>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct OrderDelivery {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub status: Option<String>,
    #[serde(default, deserialize_with = "de::model", skip_serializing_if = "Option::is_none")]
    pub platform: Option<DeliveryPlatform>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub address: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub customer_phone: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub courier_name: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub payment_method: Option<String>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub fee: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub platform_total: Option<f64>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub accepted_at: Option<DateTime<Utc>>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Order {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub number: Option<String>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub daily_number: Option<i64>,
    #[serde(
        default,
        deserialize_with = "de::enumeration",
        skip_serializing_if = "Option::is_none"
    )]
    pub kind: Option<OrderKind>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub order_type: Option<String>,
    #[serde(
        default,
        deserialize_with = "de::enumeration",
        skip_serializing_if = "Option::is_none"
    )]
    pub status: Option<OrderStatus>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub table_id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub bill_id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub customer_name: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub allergy_note: Option<String>,
    #[serde(default, deserialize_with = "de::models", skip_serializing_if = "Vec::is_empty")]
    pub items: Vec<OrderItem>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub subtotal: Option<f64>,
    #[serde(default, deserialize_with = "de::model", skip_serializing_if = "Option::is_none")]
    pub delivery: Option<OrderDelivery>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub created_at: Option<DateTime<Utc>>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub updated_at: Option<DateTime<Utc>>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Bill {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub table_id: Option<String>,
    #[serde(
        default,
        deserialize_with = "de::enumeration",
        skip_serializing_if = "Option::is_none"
    )]
    pub status: Option<BillStatus>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub guests: Option<i64>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub waiter: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub customer_id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub reservation_id: Option<String>,
    #[serde(default, deserialize_with = "de::strings", skip_serializing_if = "Vec::is_empty")]
    pub order_ids: Vec<String>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub subtotal: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub discount_percent: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub bill_discount: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub service_fee_percent: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub service_fee: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub total: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub paid: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub remaining: Option<f64>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub opened_at: Option<DateTime<Utc>>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub closed_at: Option<DateTime<Utc>>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct PaymentCard {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub masked_pan: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub scheme: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub bank: Option<String>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct PaymentPlatform {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Payment {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(
        default,
        deserialize_with = "de::enumeration",
        skip_serializing_if = "Option::is_none"
    )]
    pub status: Option<PaymentStatus>,
    #[serde(
        default,
        deserialize_with = "de::enumeration",
        skip_serializing_if = "Option::is_none"
    )]
    pub method: Option<PaymentMethod>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub recorded_method: Option<String>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub amount: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub tip: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub refunded_amount: Option<f64>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub refunded_at: Option<DateTime<Utc>>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub refund_reason: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub bill_id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub reservation_id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub order_id: Option<String>,
    #[serde(
        default,
        deserialize_with = "de::enumeration",
        skip_serializing_if = "Option::is_none"
    )]
    pub taken_at: Option<PaymentTakenAt>,
    #[serde(default, deserialize_with = "de::model", skip_serializing_if = "Option::is_none")]
    pub card: Option<PaymentCard>,
    #[serde(default, deserialize_with = "de::model", skip_serializing_if = "Option::is_none")]
    pub platform: Option<PaymentPlatform>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub created_at: Option<DateTime<Utc>>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub settled_at: Option<DateTime<Utc>>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Hall {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub position: Option<i64>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Table {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub label: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub hall_id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub zone: Option<String>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub seats: Option<i64>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub shape: Option<String>,
    #[serde(
        default,
        deserialize_with = "de::enumeration",
        skip_serializing_if = "Option::is_none"
    )]
    pub status: Option<TableStatus>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub guests: Option<i64>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub waiter: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub seated_since: Option<String>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub open_orders: Option<i64>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub bill_id: Option<String>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub bill_total: Option<f64>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub bill_requested: Option<bool>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub bill_settled: Option<bool>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub merged_into: Option<String>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Customer {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub phone: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub created_at: Option<DateTime<Utc>>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub updated_at: Option<DateTime<Utc>>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct LoyaltyProgram {
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub stamps_needed: Option<i64>,
    #[serde(
        default,
        deserialize_with = "de::enumeration",
        skip_serializing_if = "Option::is_none"
    )]
    pub earn_by: Option<LoyaltyProgramEarnBy>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub min_bill: Option<f64>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub once_per_day: Option<bool>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub reward_name: Option<String>,
    #[serde(
        default,
        deserialize_with = "de::enumeration",
        skip_serializing_if = "Option::is_none"
    )]
    pub reward_scope: Option<LoyaltyProgramRewardScope>,
    #[serde(default, deserialize_with = "de::strings", skip_serializing_if = "Vec::is_empty")]
    pub reward_categories: Vec<String>,
    #[serde(default, deserialize_with = "de::strings", skip_serializing_if = "Vec::is_empty")]
    pub reward_product_ids: Vec<String>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub reward_max_price: Option<f64>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub terms: Option<String>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct LoyaltyCard {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub phone: Option<String>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub stamps: Option<i64>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub total_stamps: Option<i64>,
    #[serde(default, deserialize_with = "de::int", skip_serializing_if = "Option::is_none")]
    pub redeemed: Option<i64>,
    #[serde(
        default,
        deserialize_with = "de::enumeration",
        skip_serializing_if = "Option::is_none"
    )]
    pub source: Option<LoyaltyCardSource>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub last_visit_at: Option<DateTime<Utc>>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub created_at: Option<DateTime<Utc>>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub updated_at: Option<DateTime<Utc>>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Ingredient {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub unit: Option<String>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub stock: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub on_open_bills: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub available: Option<f64>,
    #[serde(
        default,
        deserialize_with = "de::enumeration",
        skip_serializing_if = "Option::is_none"
    )]
    pub state: Option<IngredientState>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub low_stock: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub par_stock: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub cost_per_unit: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub value: Option<f64>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub prepared: Option<bool>,
    #[serde(default, deserialize_with = "de::floats", skip_serializing_if = "HashMap::is_empty")]
    pub by_store: HashMap<String, f64>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub updated_at: Option<DateTime<Utc>>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct StockStore {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub is_default: Option<bool>,
    #[serde(default, deserialize_with = "de::strings", skip_serializing_if = "Vec::is_empty")]
    pub stations: Vec<String>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct StockMove {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub ingredient_id: Option<String>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub qty: Option<f64>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub reason: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub order_id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub invoice_id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub store_id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub created_at: Option<DateTime<Utc>>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct ReviewRatings {
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub food: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub service: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub atmosphere: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub cleanliness: Option<f64>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub price: Option<f64>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
#[non_exhaustive]
pub struct Review {
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub author: Option<String>,
    #[serde(default, deserialize_with = "de::float", skip_serializing_if = "Option::is_none")]
    pub overall: Option<f64>,
    #[serde(default, deserialize_with = "de::model", skip_serializing_if = "Option::is_none")]
    pub ratings: Option<ReviewRatings>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub body: Option<String>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub visit_type: Option<String>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub visited_on: Option<DateTime<Utc>>,
    #[serde(default, deserialize_with = "de::boolean", skip_serializing_if = "Option::is_none")]
    pub verified: Option<bool>,
    #[serde(default, deserialize_with = "de::string", skip_serializing_if = "Option::is_none")]
    pub reply: Option<String>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub replied_at: Option<DateTime<Utc>>,
    #[serde(default, deserialize_with = "de::datetime", skip_serializing_if = "Option::is_none")]
    pub created_at: Option<DateTime<Utc>>,
    #[serde(flatten)]
    pub extra: Map<String, Value>,
}

pub type ZReport = Map<String, Value>;
