#pragma once

#include <chrono>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

#include <nlohmann/json.hpp>

#include "noosh24/client.hpp"
#include "noosh24/errors.hpp"
#include "noosh24/time.hpp"
#include "noosh24/transport.hpp"

namespace noosh24::detail {

using json = nlohmann::json;
using Query = std::vector<std::pair<std::string, std::string>>;

std::string percent_encode(std::string_view value);
std::string encode_query(const Query& query);
std::string format_number(double value);
std::optional<double> parse_number(std::string_view text);
std::string_view trim(std::string_view text);
std::string lower(std::string_view text);

std::optional<Timestamp> parse_timestamp(std::string_view text);

std::optional<std::string> read_string(const json& data, std::string_view key);
std::optional<std::int64_t> read_int(const json& data, std::string_view key);
std::optional<double> read_double(const json& data, std::string_view key);
std::optional<bool> read_bool(const json& data, std::string_view key);
std::optional<Timestamp> read_timestamp(const json& data, std::string_view key);
std::vector<std::string> read_strings(const json& data, std::string_view key);
std::map<std::string, double> read_doubles(const json& data, std::string_view key);
const json* find(const json& data, std::string_view key);

template <class T>
std::optional<T> read_object(const json& data, std::string_view key)
{
    const json* value = find(data, key);
    if (value == nullptr || !value->is_object()) {
        return std::nullopt;
    }
    return T::from_json(*value);
}

template <class T>
std::vector<T> read_list(const json& data, std::string_view key)
{
    std::vector<T> out;
    const json* value = find(data, key);
    if (value == nullptr || !value->is_array()) {
        return out;
    }
    for (const auto& item : *value) {
        if (item.is_object()) {
            out.push_back(T::from_json(item));
        }
    }
    return out;
}

template <class T>
std::map<std::string, T> read_map(const json& data, std::string_view key)
{
    std::map<std::string, T> out;
    const json* value = find(data, key);
    if (value == nullptr || !value->is_object()) {
        return out;
    }
    for (const auto& [name, item] : value->items()) {
        if (item.is_object()) {
            out.emplace(name, T::from_json(item));
        }
    }
    return out;
}

template <class T>
T build(const json& data)
{
    return T::from_json(data.is_object() ? data : json::object());
}

[[noreturn]] void throw_api_error(int status, const Headers& headers, const std::string& body);

struct Result {
    int status = 0;
    json data;
};

class Core {
public:
    Core(std::string api_key, ClientOptions options);

    Result request(std::string_view method, std::string_view path, const Query& query = {},
                   const std::optional<std::string>& body = std::nullopt, bool retryable = true);

private:
    std::string api_key_;
    std::string base_url_;
    std::chrono::milliseconds timeout_;
    int max_retries_;
    std::string user_agent_;
    std::shared_ptr<Transport> transport_;
    std::function<void(std::chrono::milliseconds)> sleep_;
};

}
