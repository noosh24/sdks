#include <array>
#include <cctype>
#include <charconv>
#include <cmath>
#include <limits>
#include <system_error>

#include "internal.hpp"

namespace noosh24::detail {

namespace {

bool unreserved(unsigned char c)
{
    return std::isalnum(c) != 0 || c == '-' || c == '.' || c == '_' || c == '~';
}

std::string chars(double value, std::chars_format format)
{
    std::array<char, 512> buffer{};
    auto [end, error] = std::to_chars(buffer.data(), buffer.data() + buffer.size(), value, format);
    if (error != std::errc{}) {
        return std::to_string(value);
    }
    return std::string(buffer.data(), end);
}

bool digits(std::string_view text, std::size_t& pos, std::size_t count, int& out)
{
    if (pos + count > text.size()) {
        return false;
    }
    int value = 0;
    for (std::size_t i = 0; i < count; ++i) {
        char c = text[pos + i];
        if (c < '0' || c > '9') {
            return false;
        }
        value = value * 10 + (c - '0');
    }
    pos += count;
    out = value;
    return true;
}

bool expect(std::string_view text, std::size_t& pos, char c)
{
    if (pos < text.size() && text[pos] == c) {
        ++pos;
        return true;
    }
    return false;
}

std::optional<std::string> scalar_string(const json& value)
{
    switch (value.type()) {
    case json::value_t::string:
        return value.get<std::string>();
    case json::value_t::boolean:
        return value.get<bool>() ? "true" : "false";
    case json::value_t::number_integer:
        return std::to_string(value.get<std::int64_t>());
    case json::value_t::number_unsigned:
        return std::to_string(value.get<std::uint64_t>());
    case json::value_t::number_float: {
        double number = value.get<double>();
        if (!std::isfinite(number)) {
            return value.dump();
        }
        if (number == std::trunc(number)) {
            return chars(number + 0.0, std::chars_format::fixed) + ".0";
        }
        return format_number(number);
    }
    default:
        return std::nullopt;
    }
}

}

std::string percent_encode(std::string_view value)
{
    static constexpr char hex[] = "0123456789ABCDEF";
    std::string out;
    out.reserve(value.size());
    for (char raw : value) {
        auto c = static_cast<unsigned char>(raw);
        if (unreserved(c)) {
            out.push_back(raw);
        } else {
            out.push_back('%');
            out.push_back(hex[c >> 4]);
            out.push_back(hex[c & 0x0F]);
        }
    }
    return out;
}

std::string encode_query(const Query& query)
{
    std::string out;
    for (const auto& [name, value] : query) {
        out += out.empty() ? '?' : '&';
        out += percent_encode(name);
        out += '=';
        out += percent_encode(value);
    }
    return out;
}

std::string format_number(double value)
{
    if (value == std::trunc(value)) {
        return chars(value + 0.0, std::chars_format::fixed);
    }
    if (std::fabs(value) >= 1e-4) {
        return chars(value, std::chars_format::fixed);
    }
    return chars(value, std::chars_format::scientific);
}

std::optional<double> parse_number(std::string_view text)
{
    text = trim(text);
    std::size_t pos = 0;
    bool negative = false;
    if (pos < text.size() && (text[pos] == '+' || text[pos] == '-')) {
        negative = text[pos] == '-';
        ++pos;
    }
    double value = 0;
    bool any = false;
    while (pos < text.size() && text[pos] >= '0' && text[pos] <= '9') {
        value = value * 10 + (text[pos] - '0');
        any = true;
        ++pos;
    }
    if (pos < text.size() && text[pos] == '.') {
        ++pos;
        double scale = 0.1;
        while (pos < text.size() && text[pos] >= '0' && text[pos] <= '9') {
            value += (text[pos] - '0') * scale;
            scale /= 10;
            any = true;
            ++pos;
        }
    }
    if (!any || pos != text.size()) {
        return std::nullopt;
    }
    return negative ? -value : value;
}

std::string_view trim(std::string_view text)
{
    auto space = [](char c) { return std::isspace(static_cast<unsigned char>(c)) != 0; };
    while (!text.empty() && space(text.front())) {
        text.remove_prefix(1);
    }
    while (!text.empty() && space(text.back())) {
        text.remove_suffix(1);
    }
    return text;
}

std::string lower(std::string_view text)
{
    std::string out(text);
    for (char& c : out) {
        c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    }
    return out;
}

std::optional<Timestamp> parse_timestamp(std::string_view text)
{
    using namespace std::chrono;
    text = trim(text);
    std::size_t pos = 0;
    int year = 0;
    int month = 0;
    int day = 0;
    if (!digits(text, pos, 4, year) || !expect(text, pos, '-') || !digits(text, pos, 2, month) ||
        !expect(text, pos, '-') || !digits(text, pos, 2, day)) {
        return std::nullopt;
    }
    year_month_day date{std::chrono::year{year}, std::chrono::month{static_cast<unsigned>(month)},
                        std::chrono::day{static_cast<unsigned>(day)}};
    if (!date.ok()) {
        return std::nullopt;
    }
    Timestamp result{sys_days{date}};
    if (pos == text.size()) {
        return result;
    }
    if (text[pos] != 'T' && text[pos] != 't' && text[pos] != ' ') {
        return std::nullopt;
    }
    ++pos;
    int hour = 0;
    int minute = 0;
    int second = 0;
    if (!digits(text, pos, 2, hour) || !expect(text, pos, ':') || !digits(text, pos, 2, minute)) {
        return std::nullopt;
    }
    if (expect(text, pos, ':') && !digits(text, pos, 2, second)) {
        return std::nullopt;
    }
    if (hour > 23 || minute > 59 || second > 59) {
        return std::nullopt;
    }
    std::int64_t micros = 0;
    if (pos < text.size() && (text[pos] == '.' || text[pos] == ',')) {
        ++pos;
        int count = 0;
        while (pos < text.size() && text[pos] >= '0' && text[pos] <= '9') {
            if (count < 6) {
                micros = micros * 10 + (text[pos] - '0');
            }
            ++count;
            ++pos;
        }
        if (count == 0) {
            return std::nullopt;
        }
        for (int i = count; i < 6; ++i) {
            micros *= 10;
        }
    }
    minutes offset{0};
    if (pos < text.size()) {
        char sign = text[pos];
        if (sign == 'Z' || sign == 'z') {
            ++pos;
        } else if (sign == '+' || sign == '-') {
            ++pos;
            int offset_hours = 0;
            int offset_minutes = 0;
            if (!digits(text, pos, 2, offset_hours)) {
                return std::nullopt;
            }
            expect(text, pos, ':');
            if (pos < text.size() && !digits(text, pos, 2, offset_minutes)) {
                return std::nullopt;
            }
            if (offset_hours > 23 || offset_minutes > 59) {
                return std::nullopt;
            }
            offset = hours{offset_hours} + minutes{offset_minutes};
            if (sign == '-') {
                offset = -offset;
            }
        } else {
            return std::nullopt;
        }
    }
    if (pos != text.size()) {
        return std::nullopt;
    }
    result += hours{hour} + minutes{minute} + seconds{second} + microseconds{micros};
    return result - offset;
}

const json* find(const json& data, std::string_view key)
{
    if (!data.is_object()) {
        return nullptr;
    }
    auto it = data.find(key);
    if (it == data.end()) {
        return nullptr;
    }
    return &*it;
}

std::optional<std::string> read_string(const json& data, std::string_view key)
{
    const json* value = find(data, key);
    return value == nullptr ? std::nullopt : scalar_string(*value);
}

std::optional<std::int64_t> read_int(const json& data, std::string_view key)
{
    const json* value = find(data, key);
    if (value == nullptr) {
        return std::nullopt;
    }
    switch (value->type()) {
    case json::value_t::number_integer:
        return value->get<std::int64_t>();
    case json::value_t::number_unsigned: {
        auto number = value->get<std::uint64_t>();
        if (number > static_cast<std::uint64_t>(std::numeric_limits<std::int64_t>::max())) {
            return std::nullopt;
        }
        return static_cast<std::int64_t>(number);
    }
    case json::value_t::number_float: {
        double number = std::trunc(value->get<double>());
        if (!std::isfinite(number) || number < -9.2e18 || number > 9.2e18) {
            return std::nullopt;
        }
        return static_cast<std::int64_t>(number);
    }
    default:
        return std::nullopt;
    }
}

std::optional<double> read_double(const json& data, std::string_view key)
{
    const json* value = find(data, key);
    if (value == nullptr || !value->is_number()) {
        return std::nullopt;
    }
    return value->get<double>();
}

std::optional<bool> read_bool(const json& data, std::string_view key)
{
    const json* value = find(data, key);
    if (value == nullptr) {
        return std::nullopt;
    }
    switch (value->type()) {
    case json::value_t::boolean:
        return value->get<bool>();
    case json::value_t::number_integer:
    case json::value_t::number_unsigned:
    case json::value_t::number_float:
        return value->get<double>() != 0;
    case json::value_t::string:
        return !value->get_ref<const std::string&>().empty();
    default:
        return std::nullopt;
    }
}

std::optional<Timestamp> read_timestamp(const json& data, std::string_view key)
{
    const json* value = find(data, key);
    if (value == nullptr || !value->is_string()) {
        return std::nullopt;
    }
    return parse_timestamp(value->get_ref<const std::string&>());
}

std::vector<std::string> read_strings(const json& data, std::string_view key)
{
    std::vector<std::string> out;
    const json* value = find(data, key);
    if (value == nullptr || !value->is_array()) {
        return out;
    }
    for (const auto& item : *value) {
        if (auto text = scalar_string(item)) {
            out.push_back(std::move(*text));
        }
    }
    return out;
}

std::map<std::string, double> read_doubles(const json& data, std::string_view key)
{
    std::map<std::string, double> out;
    const json* value = find(data, key);
    if (value == nullptr || !value->is_object()) {
        return out;
    }
    for (const auto& [name, item] : value->items()) {
        if (item.is_number()) {
            out.emplace(name, item.get<double>());
        }
    }
    return out;
}

}
