#pragma once

#include <chrono>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include <noosh24/models.hpp>
#include <noosh24/page.hpp>

namespace noosh24 {

namespace detail {
class Core;
}

struct ListParams {
    std::optional<std::int64_t> limit{};
    std::optional<std::int64_t> offset{};
    std::vector<std::string> sort{};
    std::string where{};
};

struct ProductListParams {
    std::optional<std::int64_t> limit{};
    std::optional<std::int64_t> offset{};
    std::vector<std::string> sort{};
    std::string where{};
    std::vector<std::string> expand{};
};

class Date {
public:
    Date() = default;
    Date(const char* text);
    Date(std::string text) : text_{std::move(text)} {}
    Date(std::string_view text) : text_{text} {}
    Date(std::chrono::year_month_day day);
    Date(std::chrono::sys_days day) : Date{std::chrono::year_month_day{day}} {}

    [[nodiscard]] const std::string& str() const noexcept { return text_; }

private:
    std::string text_{};
};

struct PreOrderLine {
    std::string item_id{};
    int qty = 0;
    std::optional<std::string> note{};
};

struct NewReservation {
    Date date{};
    std::string time{};
    int guests = 0;
    std::string guest_name{};
    std::string phone{};
    std::optional<std::string> email{};
    std::optional<std::string> table_id{};
    std::optional<std::string> zone{};
    std::optional<std::string> special_request{};
    std::optional<std::string> allergy_note{};
    std::optional<bool> birthday{};
    std::optional<bool> child_chair{};
    std::vector<PreOrderLine> pre_order{};
    std::optional<std::string> external_ref{};
};

struct CreateReservationResult {
    Reservation reservation{};
    bool created = false;
};

class Resource {
public:
    explicit Resource(detail::Core& core) noexcept : core_{&core} {}

protected:
    detail::Core* core_;
};

class Menu : public Resource {
public:
    using Resource::Resource;

    [[nodiscard]] std::vector<Category> list_categories() const;
    [[nodiscard]] Page<Product> list_products(const ProductListParams& params = {}) const;
    [[nodiscard]] ItemRange<Product> iterate_products(const ProductListParams& params = {}) const;
    [[nodiscard]] Product get_product(std::string_view id, const std::vector<std::string>& expand = {}) const;
    [[nodiscard]] std::vector<StopListItem> get_stop_list() const;
};

class Reservations : public Resource {
public:
    using Resource::Resource;

    [[nodiscard]] Page<Reservation> list(const ListParams& params = {}) const;
    [[nodiscard]] ItemRange<Reservation> iterate(const ListParams& params = {}) const;
    [[nodiscard]] Reservation get(std::string_view id) const;
    [[nodiscard]] TableAvailability availability(const Date& date, std::string_view time,
                                                 std::optional<int> guests = std::nullopt) const;
    CreateReservationResult create(const NewReservation& reservation) const;
    Reservation cancel(std::string_view id) const;
};

class Orders : public Resource {
public:
    using Resource::Resource;

    [[nodiscard]] Page<Order> list(const ListParams& params = {}) const;
    [[nodiscard]] ItemRange<Order> iterate(const ListParams& params = {}) const;
    [[nodiscard]] Order get(std::string_view id) const;
    [[nodiscard]] Page<Bill> list_bills(const ListParams& params = {}) const;
    [[nodiscard]] ItemRange<Bill> iterate_bills(const ListParams& params = {}) const;
    [[nodiscard]] Bill get_bill(std::string_view id) const;
};

class Payments : public Resource {
public:
    using Resource::Resource;

    [[nodiscard]] Page<Payment> list(const ListParams& params = {}) const;
    [[nodiscard]] ItemRange<Payment> iterate(const ListParams& params = {}) const;
    [[nodiscard]] Payment get(std::string_view id) const;
    [[nodiscard]] ZReport z_report(const std::optional<Date>& date = std::nullopt) const;
};

class Tables : public Resource {
public:
    using Resource::Resource;

    [[nodiscard]] std::vector<Table> list() const;
    [[nodiscard]] std::vector<Hall> list_halls() const;
};

class Customers : public Resource {
public:
    using Resource::Resource;

    [[nodiscard]] Page<Customer> list(const ListParams& params = {}) const;
    [[nodiscard]] ItemRange<Customer> iterate(const ListParams& params = {}) const;
    [[nodiscard]] Customer get(std::string_view id) const;
};

class Loyalty : public Resource {
public:
    using Resource::Resource;

    [[nodiscard]] LoyaltyProgram get_program() const;
    [[nodiscard]] Page<LoyaltyCard> list_cards(const ListParams& params = {}) const;
    [[nodiscard]] ItemRange<LoyaltyCard> iterate_cards(const ListParams& params = {}) const;
};

class Stock : public Resource {
public:
    using Resource::Resource;

    [[nodiscard]] Page<Ingredient> list_ingredients(const ListParams& params = {}) const;
    [[nodiscard]] ItemRange<Ingredient> iterate_ingredients(const ListParams& params = {}) const;
    [[nodiscard]] Page<StockMove> list_moves(const ListParams& params = {}) const;
    [[nodiscard]] ItemRange<StockMove> iterate_moves(const ListParams& params = {}) const;
    [[nodiscard]] std::vector<StockStore> list_stores() const;
};

class Reviews : public Resource {
public:
    using Resource::Resource;

    [[nodiscard]] Page<Review> list(const ListParams& params = {}) const;
    [[nodiscard]] ItemRange<Review> iterate(const ListParams& params = {}) const;
};

}
