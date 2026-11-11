#include <format>
#include <stdexcept>

#include "internal.hpp"
#include "noosh24/resources.hpp"

namespace noosh24 {

namespace {

using detail::Core;
using detail::json;
using detail::Query;

struct ListQuery {
    std::optional<std::int64_t> limit;
    std::optional<std::int64_t> offset;
    std::vector<std::string> sort;
    std::string where;
    std::vector<std::string> expand;

    [[nodiscard]] Query pairs() const
    {
        Query out;
        if (limit) {
            out.emplace_back("limit", std::to_string(*limit));
        }
        if (offset) {
            out.emplace_back("offset", std::to_string(*offset));
        }
        for (const auto& value : sort) {
            if (!value.empty()) {
                out.emplace_back("sort", value);
            }
        }
        if (!where.empty()) {
            out.emplace_back("where", where);
        }
        for (const auto& value : expand) {
            if (!value.empty()) {
                out.emplace_back("expand", value);
            }
        }
        return out;
    }
};

bool any(const std::vector<std::string>& values)
{
    for (const auto& value : values) {
        if (!value.empty()) {
            return true;
        }
    }
    return false;
}

ListQuery list_query(const ListParams& params)
{
    return ListQuery{params.limit, params.offset, params.sort, params.where, {}};
}

ListQuery list_query(const ProductListParams& params)
{
    return ListQuery{params.limit, params.offset, params.sort, params.where, params.expand};
}

std::string id_path(std::string_view id)
{
    if (detail::trim(id).empty()) {
        throw std::invalid_argument("An id is required");
    }
    return detail::percent_encode(id);
}

std::int64_t int_or(const json& data, std::string_view key, std::int64_t fallback)
{
    return detail::read_int(data, key).value_or(fallback);
}

template <class T>
std::vector<T> items_of(const json& data)
{
    return detail::read_list<T>(data, "items");
}

template <class T>
Page<T> fetch_page(Core& core, const std::string& path, const ListQuery& query)
{
    json data = core.request("GET", path, query.pairs()).data;
    Page<T> page;
    page.items = items_of<T>(data);
    auto count = static_cast<std::int64_t>(page.items.size());
    page.total = int_or(data, "total", count);
    page.limit = int_or(data, "limit", query.limit.value_or(count));
    page.offset = int_or(data, "offset", query.offset.value_or(0));
    return page;
}

template <class T>
ItemRange<T> paginate(Core& core, std::string path, ListQuery query, std::int64_t page_size)
{
    if (!query.limit) {
        query.limit = page_size;
    }
    std::int64_t start = query.offset.value_or(0);
    Core* target = &core;
    return ItemRange<T>{start, [target, path = std::move(path), query = std::move(query)](std::int64_t offset) {
                            ListQuery next = query;
                            next.offset = offset;
                            return fetch_page<T>(*target, path, next);
                        }};
}

template <class T>
std::vector<T> fetch_all(Core& core, std::string_view path)
{
    return items_of<T>(core.request("GET", path).data);
}

template <class T>
T fetch_one(Core& core, std::string_view path, const Query& query = {})
{
    return detail::build<T>(core.request("GET", path, query).data);
}

}

Date::Date(const char* text)
{
    if (text == nullptr) {
        throw std::invalid_argument("A date is required");
    }
    text_ = text;
}

Date::Date(std::chrono::year_month_day day)
{
    if (!day.ok()) {
        throw std::invalid_argument("A valid date is required");
    }
    text_ = std::format("{:04}-{:02}-{:02}", static_cast<int>(day.year()), static_cast<unsigned>(day.month()),
                        static_cast<unsigned>(day.day()));
}

std::vector<Category> Menu::list_categories() const
{
    return fetch_all<Category>(*core_, "/menu/categories");
}

Page<Product> Menu::list_products(const ProductListParams& params) const
{
    return fetch_page<Product>(*core_, "/menu/products", list_query(params));
}

ItemRange<Product> Menu::iterate_products(const ProductListParams& params) const
{
    return paginate<Product>(*core_, "/menu/products", list_query(params), any(params.expand) ? 50 : 100);
}

Product Menu::get_product(std::string_view id, const std::vector<std::string>& expand) const
{
    Query query;
    for (const auto& value : expand) {
        if (!value.empty()) {
            query.emplace_back("expand", value);
        }
    }
    return fetch_one<Product>(*core_, "/menu/products/" + id_path(id), query);
}

std::vector<StopListItem> Menu::get_stop_list() const
{
    return fetch_all<StopListItem>(*core_, "/menu/stop-list");
}

Page<Reservation> Reservations::list(const ListParams& params) const
{
    return fetch_page<Reservation>(*core_, "/reservations", list_query(params));
}

ItemRange<Reservation> Reservations::iterate(const ListParams& params) const
{
    return paginate<Reservation>(*core_, "/reservations", list_query(params), 100);
}

Reservation Reservations::get(std::string_view id) const
{
    return fetch_one<Reservation>(*core_, "/reservations/" + id_path(id));
}

TableAvailability Reservations::availability(const Date& date, std::string_view time,
                                             std::optional<int> guests) const
{
    Query query{{"date", date.str()}, {"time", std::string(time)}};
    if (guests) {
        query.emplace_back("guests", std::to_string(*guests));
    }
    return fetch_one<TableAvailability>(*core_, "/reservations/availability", query);
}

CreateReservationResult Reservations::create(const NewReservation& reservation) const
{
    nlohmann::ordered_json body;
    body["date"] = reservation.date.str();
    body["time"] = reservation.time;
    body["guests"] = reservation.guests;
    body["guestName"] = reservation.guest_name;
    body["phone"] = reservation.phone;
    auto put = [&body](const char* key, const auto& value) {
        if (value) {
            body[key] = *value;
        }
    };
    put("email", reservation.email);
    put("tableId", reservation.table_id);
    put("zone", reservation.zone);
    put("specialRequest", reservation.special_request);
    put("allergyNote", reservation.allergy_note);
    put("birthday", reservation.birthday);
    put("childChair", reservation.child_chair);
    put("externalRef", reservation.external_ref);
    if (!reservation.pre_order.empty()) {
        auto lines = nlohmann::ordered_json::array();
        for (const auto& line : reservation.pre_order) {
            nlohmann::ordered_json item;
            item["itemId"] = line.item_id;
            item["qty"] = line.qty;
            if (line.note) {
                item["note"] = *line.note;
            }
            lines.push_back(std::move(item));
        }
        body["preOrder"] = std::move(lines);
    }
    bool idempotent = reservation.external_ref && !detail::trim(*reservation.external_ref).empty();
    auto result = core_->request("POST", "/reservations", {},
                                 body.dump(-1, ' ', false, nlohmann::ordered_json::error_handler_t::replace),
                                 idempotent);
    return CreateReservationResult{detail::build<Reservation>(result.data), result.status == 201};
}

Reservation Reservations::cancel(std::string_view id) const
{
    return detail::build<Reservation>(core_->request("POST", "/reservations/" + id_path(id) + "/cancel").data);
}

Page<Order> Orders::list(const ListParams& params) const
{
    return fetch_page<Order>(*core_, "/orders", list_query(params));
}

ItemRange<Order> Orders::iterate(const ListParams& params) const
{
    return paginate<Order>(*core_, "/orders", list_query(params), 100);
}

Order Orders::get(std::string_view id) const
{
    return fetch_one<Order>(*core_, "/orders/" + id_path(id));
}

Page<Bill> Orders::list_bills(const ListParams& params) const
{
    return fetch_page<Bill>(*core_, "/bills", list_query(params));
}

ItemRange<Bill> Orders::iterate_bills(const ListParams& params) const
{
    return paginate<Bill>(*core_, "/bills", list_query(params), 50);
}

Bill Orders::get_bill(std::string_view id) const
{
    return fetch_one<Bill>(*core_, "/bills/" + id_path(id));
}

Page<Payment> Payments::list(const ListParams& params) const
{
    return fetch_page<Payment>(*core_, "/payments", list_query(params));
}

ItemRange<Payment> Payments::iterate(const ListParams& params) const
{
    return paginate<Payment>(*core_, "/payments", list_query(params), 100);
}

Payment Payments::get(std::string_view id) const
{
    return fetch_one<Payment>(*core_, "/payments/" + id_path(id));
}

ZReport Payments::z_report(const std::optional<Date>& date) const
{
    Query query;
    if (date) {
        query.emplace_back("date", date->str());
    }
    json data = core_->request("GET", "/reports/z", query).data;
    return data.is_object() ? data : json::object();
}

std::vector<Table> Tables::list() const
{
    return fetch_all<Table>(*core_, "/tables");
}

std::vector<Hall> Tables::list_halls() const
{
    return fetch_all<Hall>(*core_, "/halls");
}

Page<Customer> Customers::list(const ListParams& params) const
{
    return fetch_page<Customer>(*core_, "/customers", list_query(params));
}

ItemRange<Customer> Customers::iterate(const ListParams& params) const
{
    return paginate<Customer>(*core_, "/customers", list_query(params), 100);
}

Customer Customers::get(std::string_view id) const
{
    return fetch_one<Customer>(*core_, "/customers/" + id_path(id));
}

LoyaltyProgram Loyalty::get_program() const
{
    return fetch_one<LoyaltyProgram>(*core_, "/loyalty/program");
}

Page<LoyaltyCard> Loyalty::list_cards(const ListParams& params) const
{
    return fetch_page<LoyaltyCard>(*core_, "/loyalty/cards", list_query(params));
}

ItemRange<LoyaltyCard> Loyalty::iterate_cards(const ListParams& params) const
{
    return paginate<LoyaltyCard>(*core_, "/loyalty/cards", list_query(params), 100);
}

Page<Ingredient> Stock::list_ingredients(const ListParams& params) const
{
    return fetch_page<Ingredient>(*core_, "/stock/ingredients", list_query(params));
}

ItemRange<Ingredient> Stock::iterate_ingredients(const ListParams& params) const
{
    return paginate<Ingredient>(*core_, "/stock/ingredients", list_query(params), 100);
}

Page<StockMove> Stock::list_moves(const ListParams& params) const
{
    return fetch_page<StockMove>(*core_, "/stock/moves", list_query(params));
}

ItemRange<StockMove> Stock::iterate_moves(const ListParams& params) const
{
    return paginate<StockMove>(*core_, "/stock/moves", list_query(params), 100);
}

std::vector<StockStore> Stock::list_stores() const
{
    return fetch_all<StockStore>(*core_, "/stock/stores");
}

Page<Review> Reviews::list(const ListParams& params) const
{
    return fetch_page<Review>(*core_, "/reviews", list_query(params));
}

ItemRange<Review> Reviews::iterate(const ListParams& params) const
{
    return paginate<Review>(*core_, "/reviews", list_query(params), 100);
}

}
