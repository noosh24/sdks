#pragma once

#include <chrono>
#include <concepts>
#include <cstddef>
#include <initializer_list>
#include <string>
#include <string_view>
#include <type_traits>
#include <vector>

#include <noosh24/time.hpp>

namespace noosh24 {

namespace detail {

std::string string_literal(std::string_view value);
std::string number_literal(long long value);
std::string number_literal(unsigned long long value);
std::string number_literal(double value);
std::string date_literal(std::chrono::year_month_day value);
std::string date_time_literal(const OffsetDateTime& value);
[[noreturn]] void null_literal();

template <class T>
concept where_integer = std::integral<T> && !std::same_as<T, bool> && !std::same_as<T, char> &&
                        !std::same_as<T, wchar_t> && !std::same_as<T, char8_t> && !std::same_as<T, char16_t> &&
                        !std::same_as<T, char32_t>;

}

class Literal {
public:
    Literal(const char* value);
    Literal(const std::string& value) : text_{detail::string_literal(value)} {}
    Literal(std::string_view value) : text_{detail::string_literal(value)} {}
    Literal(bool value) : text_{value ? "true" : "false"} {}
    Literal(std::chrono::year_month_day value) : text_{detail::date_literal(value)} {}
    Literal(std::chrono::sys_days value) : text_{detail::date_literal(std::chrono::year_month_day{value})} {}
    Literal(const OffsetDateTime& value) : text_{detail::date_time_literal(value)} {}
    Literal(std::nullptr_t) { detail::null_literal(); }

    template <detail::where_integer T>
    Literal(T value)
    {
        if constexpr (std::is_signed_v<T>) {
            text_ = detail::number_literal(static_cast<long long>(value));
        } else {
            text_ = detail::number_literal(static_cast<unsigned long long>(value));
        }
    }

    template <std::floating_point T>
    Literal(T value) : text_{detail::number_literal(static_cast<double>(value))}
    {
    }

    template <class Duration>
    Literal(std::chrono::sys_time<Duration> value)
        : text_{detail::date_time_literal(OffsetDateTime{
              std::chrono::local_time<std::chrono::microseconds>{
                  std::chrono::floor<std::chrono::microseconds>(value).time_since_epoch()},
              std::chrono::minutes{0}})}
    {
    }

    [[nodiscard]] const std::string& str() const noexcept { return text_; }

private:
    std::string text_;
};

class Where {
public:
    Where& eq(std::string_view field, const Literal& value);
    Where& ne(std::string_view field, const Literal& value);
    Where& gt(std::string_view field, const Literal& value);
    Where& gte(std::string_view field, const Literal& value);
    Where& lt(std::string_view field, const Literal& value);
    Where& lte(std::string_view field, const Literal& value);
    Where& in(std::string_view field, std::initializer_list<Literal> values);
    Where& in(std::string_view field, const std::vector<Literal>& values);

    [[nodiscard]] std::string str() const;
    [[nodiscard]] bool empty() const noexcept { return conditions_.empty(); }
    operator std::string() const { return str(); }

private:
    Where& add(std::string_view field, std::string_view op, const Literal& value);

    std::vector<std::string> conditions_;
};

[[nodiscard]] inline Where where() { return Where{}; }

}
