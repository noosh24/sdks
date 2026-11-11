#include <cmath>
#include <format>
#include <stdexcept>

#include "internal.hpp"
#include "noosh24/where.hpp"

namespace noosh24 {

namespace detail {

namespace {

bool field_name(std::string_view name)
{
    if (name.empty()) {
        return false;
    }
    auto alpha = [](char c) { return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'); };
    if (!alpha(name.front())) {
        return false;
    }
    for (char c : name) {
        if (!alpha(c) && !(c >= '0' && c <= '9') && c != '_' && c != '.') {
            return false;
        }
    }
    return true;
}

std::string checked_field(std::string_view name)
{
    if (!field_name(name)) {
        throw std::invalid_argument("\"" + std::string(name) + "\" is not a field name");
    }
    return std::string(name);
}

}

std::string string_literal(std::string_view value)
{
    std::string out = "'";
    for (char c : value) {
        out += c;
        if (c == '\'') {
            out += '\'';
        }
    }
    out += '\'';
    return out;
}

std::string number_literal(long long value)
{
    return std::to_string(value);
}

std::string number_literal(unsigned long long value)
{
    return std::to_string(value);
}

std::string number_literal(double value)
{
    if (!std::isfinite(value)) {
        throw std::invalid_argument("Numbers in where must be finite");
    }
    return format_number(value);
}

std::string date_literal(std::chrono::year_month_day value)
{
    if (!value.ok()) {
        throw std::invalid_argument("where needs a valid date");
    }
    return std::format("'{:04}-{:02}-{:02}'", static_cast<int>(value.year()), static_cast<unsigned>(value.month()),
                       static_cast<unsigned>(value.day()));
}

std::string date_time_literal(const OffsetDateTime& value)
{
    using namespace std::chrono;
    auto day = floor<days>(value.local);
    year_month_day date{day};
    hh_mm_ss<microseconds> time{value.local - day};
    std::string out = std::format("'{:04}-{:02}-{:02}T{:02}:{:02}:{:02}", static_cast<int>(date.year()),
                                  static_cast<unsigned>(date.month()), static_cast<unsigned>(date.day()),
                                  time.hours().count(), time.minutes().count(), time.seconds().count());
    if (time.subseconds().count() != 0) {
        out += std::format(".{:06}", time.subseconds().count());
    }
    auto offset = value.offset.count();
    char sign = offset < 0 ? '-' : '+';
    offset = offset < 0 ? -offset : offset;
    out += std::format("{}{:02}:{:02}'", sign, offset / 60, offset % 60);
    return out;
}

void null_literal()
{
    throw std::invalid_argument("where takes strings, numbers, booleans and dates, not null");
}

}

Literal::Literal(const char* value)
{
    if (value == nullptr) {
        detail::null_literal();
    }
    text_ = detail::string_literal(value);
}

Where& Where::eq(std::string_view field, const Literal& value)
{
    return add(field, "=", value);
}

Where& Where::ne(std::string_view field, const Literal& value)
{
    return add(field, "!=", value);
}

Where& Where::gt(std::string_view field, const Literal& value)
{
    return add(field, ">", value);
}

Where& Where::gte(std::string_view field, const Literal& value)
{
    return add(field, ">=", value);
}

Where& Where::lt(std::string_view field, const Literal& value)
{
    return add(field, "<", value);
}

Where& Where::lte(std::string_view field, const Literal& value)
{
    return add(field, "<=", value);
}

Where& Where::in(std::string_view field, std::initializer_list<Literal> values)
{
    return in(field, std::vector<Literal>(values));
}

Where& Where::in(std::string_view field, const std::vector<Literal>& values)
{
    std::string name = detail::checked_field(field);
    if (values.empty()) {
        throw std::invalid_argument("in() needs at least one value");
    }
    std::string list;
    for (const auto& value : values) {
        if (!list.empty()) {
            list += ", ";
        }
        list += value.str();
    }
    conditions_.push_back(name + " in (" + list + ")");
    return *this;
}

std::string Where::str() const
{
    std::string out;
    for (const auto& condition : conditions_) {
        if (!out.empty()) {
            out += " AND ";
        }
        out += condition;
    }
    return out;
}

Where& Where::add(std::string_view field, std::string_view op, const Literal& value)
{
    conditions_.push_back(detail::checked_field(field) + " " + std::string(op) + " " + value.str());
    return *this;
}

}
