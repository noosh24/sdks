#pragma once

#include <chrono>

namespace noosh24 {

using Timestamp = std::chrono::sys_time<std::chrono::microseconds>;

struct OffsetDateTime {
    std::chrono::local_time<std::chrono::microseconds> local{};
    std::chrono::minutes offset{0};
};

}
