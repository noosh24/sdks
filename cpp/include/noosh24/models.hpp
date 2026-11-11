#pragma once

#include <cstdint>
#include <map>
#include <optional>
#include <string>
#include <vector>

#include <nlohmann/json.hpp>

#include <noosh24/time.hpp>

namespace noosh24 {

struct Restaurant {
    std::optional<std::string> id{};
    std::optional<std::string> name{};
    std::optional<std::string> slug{};
    nlohmann::json raw{};

    [[nodiscard]] static Restaurant from_json(const nlohmann::json& data);
};

struct ApiKeyInfo {
    std::optional<std::string> id{};
    std::optional<std::string> name{};
    std::optional<std::string> prefix{};
    std::vector<std::string> scopes{};
    nlohmann::json raw{};

    [[nodiscard]] static ApiKeyInfo from_json(const nlohmann::json& data);
};

struct Subscription {
    std::optional<std::string> status{};
    std::vector<std::string> modules{};
    nlohmann::json raw{};

    [[nodiscard]] static Subscription from_json(const nlohmann::json& data);
};

struct Features {
    std::optional<bool> loyalty{};
    std::optional<bool> inventory{};
    nlohmann::json raw{};

    [[nodiscard]] static Features from_json(const nlohmann::json& data);
};

struct Whoami {
    std::optional<Restaurant> restaurant{};
    std::optional<ApiKeyInfo> key{};
    std::optional<Subscription> subscription{};
    std::optional<Features> features{};
    nlohmann::json raw{};

    [[nodiscard]] static Whoami from_json(const nlohmann::json& data);
};

struct Category {
    std::optional<std::string> name{};
    std::optional<std::int64_t> position{};
    std::optional<std::int64_t> products{};
    std::optional<std::int64_t> available{};
    nlohmann::json raw{};

    [[nodiscard]] static Category from_json(const nlohmann::json& data);
};

struct Modifier {
    std::optional<std::string> id{};
    std::optional<std::string> name{};
    std::optional<double> price_delta{};
    std::optional<std::int64_t> position{};
    nlohmann::json raw{};

    [[nodiscard]] static Modifier from_json(const nlohmann::json& data);
};

struct ModifierGroup {
    std::optional<std::string> id{};
    std::optional<std::string> name{};
    std::optional<bool> required{};
    std::optional<std::int64_t> position{};
    std::vector<Modifier> modifiers{};
    nlohmann::json raw{};

    [[nodiscard]] static ModifierGroup from_json(const nlohmann::json& data);
};

struct ProductTranslation {
    std::optional<std::string> name{};
    std::optional<std::string> description{};
    nlohmann::json raw{};

    [[nodiscard]] static ProductTranslation from_json(const nlohmann::json& data);
};

struct Product {
    std::optional<std::string> id{};
    std::optional<std::string> name{};
    std::optional<std::string> category{};
    std::optional<std::string> description{};
    std::optional<double> price{};
    std::optional<bool> available{};
    std::optional<bool> popular{};
    std::optional<std::int64_t> position{};
    std::optional<std::int64_t> prep_minutes{};
    std::optional<std::string> station{};
    std::optional<double> vat_rate{};
    std::optional<bool> vegetarian{};
    std::optional<bool> spicy{};
    std::vector<std::string> allergens{};
    std::optional<bool> discountable{};
    std::optional<bool> has_modifiers{};
    std::optional<std::string> image{};
    std::optional<std::string> video{};
    std::vector<ModifierGroup> modifier_groups{};
    std::map<std::string, ProductTranslation> translations{};
    nlohmann::json raw{};

    [[nodiscard]] static Product from_json(const nlohmann::json& data);
};

struct StopListItem {
    std::optional<std::string> id{};
    std::optional<std::string> name{};
    std::optional<std::string> category{};
    std::optional<double> price{};
    nlohmann::json raw{};

    [[nodiscard]] static StopListItem from_json(const nlohmann::json& data);
};

struct ReservationGuest {
    std::optional<std::string> name{};
    std::optional<std::string> phone{};
    std::optional<std::string> email{};
    nlohmann::json raw{};

    [[nodiscard]] static ReservationGuest from_json(const nlohmann::json& data);
};

struct ReservationTable {
    std::optional<std::string> id{};
    std::optional<std::string> label{};
    nlohmann::json raw{};

    [[nodiscard]] static ReservationTable from_json(const nlohmann::json& data);
};

struct ReservationPreOrderItem {
    std::optional<std::string> product_id{};
    std::optional<std::string> name{};
    std::optional<double> price{};
    std::optional<std::int64_t> qty{};
    std::optional<std::string> note{};
    nlohmann::json raw{};

    [[nodiscard]] static ReservationPreOrderItem from_json(const nlohmann::json& data);
};

struct Reservation {
    std::optional<std::string> id{};
    std::optional<std::string> code{};
    std::optional<std::string> status{};
    std::optional<std::string> source{};
    std::optional<Timestamp> starts_at{};
    std::optional<Timestamp> ends_at{};
    std::optional<std::int64_t> guests{};
    std::optional<std::string> zone{};
    std::optional<ReservationTable> table{};
    std::optional<ReservationGuest> guest{};
    std::optional<std::string> special_request{};
    std::optional<std::string> allergy_note{};
    std::optional<bool> birthday{};
    std::optional<bool> child_chair{};
    std::optional<double> deposit_paid{};
    std::vector<ReservationPreOrderItem> pre_order{};
    std::optional<std::string> external_ref{};
    std::optional<Timestamp> decided_at{};
    std::optional<Timestamp> created_at{};
    std::optional<Timestamp> updated_at{};
    nlohmann::json raw{};

    [[nodiscard]] static Reservation from_json(const nlohmann::json& data);
};

struct AvailableTable {
    std::optional<std::string> id{};
    std::optional<std::string> label{};
    std::optional<std::string> hall_id{};
    std::optional<std::string> zone{};
    std::optional<std::int64_t> seats{};
    std::optional<bool> free{};
    nlohmann::json raw{};

    [[nodiscard]] static AvailableTable from_json(const nlohmann::json& data);
};

struct TableAvailability {
    std::optional<Timestamp> starts_at{};
    std::optional<Timestamp> ends_at{};
    std::optional<std::int64_t> duration_minutes{};
    std::optional<std::string> open_time{};
    std::optional<std::string> close_time{};
    std::vector<AvailableTable> tables{};
    nlohmann::json raw{};

    [[nodiscard]] static TableAvailability from_json(const nlohmann::json& data);
};

struct OrderItem {
    std::optional<std::string> id{};
    std::optional<std::string> product_id{};
    std::optional<std::string> name{};
    std::optional<std::int64_t> qty{};
    std::optional<double> price{};
    std::optional<double> list_price{};
    std::optional<std::string> modifiers{};
    std::optional<std::string> note{};
    std::optional<std::string> status{};
    std::optional<bool> comp{};
    std::optional<std::string> campaign{};
    std::optional<std::string> cancel_reason{};
    nlohmann::json raw{};

    [[nodiscard]] static OrderItem from_json(const nlohmann::json& data);
};

struct DeliveryPlatform {
    std::optional<std::string> id{};
    std::optional<std::string> name{};
    std::optional<std::string> ref{};
    nlohmann::json raw{};

    [[nodiscard]] static DeliveryPlatform from_json(const nlohmann::json& data);
};

struct OrderDelivery {
    std::optional<std::string> status{};
    std::optional<DeliveryPlatform> platform{};
    std::optional<std::string> address{};
    std::optional<std::string> customer_phone{};
    std::optional<std::string> courier_name{};
    std::optional<std::string> note{};
    std::optional<std::string> payment_method{};
    std::optional<double> fee{};
    std::optional<double> platform_total{};
    std::optional<Timestamp> accepted_at{};
    nlohmann::json raw{};

    [[nodiscard]] static OrderDelivery from_json(const nlohmann::json& data);
};

struct Order {
    std::optional<std::string> id{};
    std::optional<std::string> number{};
    std::optional<std::int64_t> daily_number{};
    std::optional<std::string> kind{};
    std::optional<std::string> order_type{};
    std::optional<std::string> status{};
    std::optional<std::string> table_id{};
    std::optional<std::string> bill_id{};
    std::optional<std::string> customer_name{};
    std::optional<std::string> allergy_note{};
    std::vector<OrderItem> items{};
    std::optional<double> subtotal{};
    std::optional<OrderDelivery> delivery{};
    std::optional<Timestamp> created_at{};
    std::optional<Timestamp> updated_at{};
    nlohmann::json raw{};

    [[nodiscard]] static Order from_json(const nlohmann::json& data);
};

struct Bill {
    std::optional<std::string> id{};
    std::optional<std::string> table_id{};
    std::optional<std::string> status{};
    std::optional<std::int64_t> guests{};
    std::optional<std::string> waiter{};
    std::optional<std::string> customer_id{};
    std::optional<std::string> reservation_id{};
    std::vector<std::string> order_ids{};
    std::optional<double> subtotal{};
    std::optional<double> discount_percent{};
    std::optional<double> bill_discount{};
    std::optional<double> service_fee_percent{};
    std::optional<double> service_fee{};
    std::optional<double> total{};
    std::optional<double> paid{};
    std::optional<double> remaining{};
    std::optional<Timestamp> opened_at{};
    std::optional<Timestamp> closed_at{};
    nlohmann::json raw{};

    [[nodiscard]] static Bill from_json(const nlohmann::json& data);
};

struct PaymentCard {
    std::optional<std::string> masked_pan{};
    std::optional<std::string> scheme{};
    std::optional<std::string> bank{};
    nlohmann::json raw{};

    [[nodiscard]] static PaymentCard from_json(const nlohmann::json& data);
};

struct PaymentPlatform {
    std::optional<std::string> id{};
    std::optional<std::string> name{};
    nlohmann::json raw{};

    [[nodiscard]] static PaymentPlatform from_json(const nlohmann::json& data);
};

struct Payment {
    std::optional<std::string> id{};
    std::optional<std::string> status{};
    std::optional<std::string> method{};
    std::optional<std::string> recorded_method{};
    std::optional<double> amount{};
    std::optional<double> tip{};
    std::optional<double> refunded_amount{};
    std::optional<Timestamp> refunded_at{};
    std::optional<std::string> refund_reason{};
    std::optional<std::string> bill_id{};
    std::optional<std::string> reservation_id{};
    std::optional<std::string> order_id{};
    std::optional<std::string> taken_at{};
    std::optional<PaymentCard> card{};
    std::optional<PaymentPlatform> platform{};
    std::optional<Timestamp> created_at{};
    std::optional<Timestamp> settled_at{};
    nlohmann::json raw{};

    [[nodiscard]] static Payment from_json(const nlohmann::json& data);
};

struct Hall {
    std::optional<std::string> id{};
    std::optional<std::string> name{};
    std::optional<std::int64_t> position{};
    nlohmann::json raw{};

    [[nodiscard]] static Hall from_json(const nlohmann::json& data);
};

struct Table {
    std::optional<std::string> id{};
    std::optional<std::string> label{};
    std::optional<std::string> hall_id{};
    std::optional<std::string> zone{};
    std::optional<std::int64_t> seats{};
    std::optional<std::string> shape{};
    std::optional<std::string> status{};
    std::optional<std::int64_t> guests{};
    std::optional<std::string> waiter{};
    std::optional<std::string> seated_since{};
    std::optional<std::int64_t> open_orders{};
    std::optional<std::string> bill_id{};
    std::optional<double> bill_total{};
    std::optional<bool> bill_requested{};
    std::optional<bool> bill_settled{};
    std::optional<std::string> merged_into{};
    nlohmann::json raw{};

    [[nodiscard]] static Table from_json(const nlohmann::json& data);
};

struct Customer {
    std::optional<std::string> id{};
    std::optional<std::string> name{};
    std::optional<std::string> phone{};
    std::optional<std::string> note{};
    std::optional<Timestamp> created_at{};
    std::optional<Timestamp> updated_at{};
    nlohmann::json raw{};

    [[nodiscard]] static Customer from_json(const nlohmann::json& data);
};

struct LoyaltyProgram {
    std::optional<std::int64_t> stamps_needed{};
    std::optional<std::string> earn_by{};
    std::optional<double> min_bill{};
    std::optional<bool> once_per_day{};
    std::optional<std::string> reward_name{};
    std::optional<std::string> reward_scope{};
    std::vector<std::string> reward_categories{};
    std::vector<std::string> reward_product_ids{};
    std::optional<double> reward_max_price{};
    std::optional<std::string> terms{};
    nlohmann::json raw{};

    [[nodiscard]] static LoyaltyProgram from_json(const nlohmann::json& data);
};

struct LoyaltyCard {
    std::optional<std::string> id{};
    std::optional<std::string> name{};
    std::optional<std::string> phone{};
    std::optional<std::int64_t> stamps{};
    std::optional<std::int64_t> total_stamps{};
    std::optional<std::int64_t> redeemed{};
    std::optional<std::string> source{};
    std::optional<Timestamp> last_visit_at{};
    std::optional<Timestamp> created_at{};
    std::optional<Timestamp> updated_at{};
    nlohmann::json raw{};

    [[nodiscard]] static LoyaltyCard from_json(const nlohmann::json& data);
};

struct Ingredient {
    std::optional<std::string> id{};
    std::optional<std::string> name{};
    std::optional<std::string> unit{};
    std::optional<double> stock{};
    std::optional<double> on_open_bills{};
    std::optional<double> available{};
    std::optional<std::string> state{};
    std::optional<double> low_stock{};
    std::optional<double> par_stock{};
    std::optional<double> cost_per_unit{};
    std::optional<double> value{};
    std::optional<bool> prepared{};
    std::map<std::string, double> by_store{};
    std::optional<Timestamp> updated_at{};
    nlohmann::json raw{};

    [[nodiscard]] static Ingredient from_json(const nlohmann::json& data);
};

struct StockStore {
    std::optional<std::string> id{};
    std::optional<std::string> name{};
    std::optional<bool> is_default{};
    std::vector<std::string> stations{};
    nlohmann::json raw{};

    [[nodiscard]] static StockStore from_json(const nlohmann::json& data);
};

struct StockMove {
    std::optional<std::string> id{};
    std::optional<std::string> ingredient_id{};
    std::optional<double> qty{};
    std::optional<std::string> reason{};
    std::optional<std::string> order_id{};
    std::optional<std::string> invoice_id{};
    std::optional<std::string> store_id{};
    std::optional<std::string> note{};
    std::optional<Timestamp> created_at{};
    nlohmann::json raw{};

    [[nodiscard]] static StockMove from_json(const nlohmann::json& data);
};

struct ReviewRatings {
    std::optional<double> food{};
    std::optional<double> service{};
    std::optional<double> atmosphere{};
    std::optional<double> cleanliness{};
    std::optional<double> price{};
    nlohmann::json raw{};

    [[nodiscard]] static ReviewRatings from_json(const nlohmann::json& data);
};

struct Review {
    std::optional<std::string> id{};
    std::optional<std::string> author{};
    std::optional<double> overall{};
    std::optional<ReviewRatings> ratings{};
    std::optional<std::string> body{};
    std::optional<std::string> visit_type{};
    std::optional<Timestamp> visited_on{};
    std::optional<bool> verified{};
    std::optional<std::string> reply{};
    std::optional<Timestamp> replied_at{};
    std::optional<Timestamp> created_at{};
    nlohmann::json raw{};

    [[nodiscard]] static Review from_json(const nlohmann::json& data);
};

using ZReport = nlohmann::json;

}
