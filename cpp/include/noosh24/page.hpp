#pragma once

#include <cstddef>
#include <cstdint>
#include <functional>
#include <iterator>
#include <memory>
#include <utility>
#include <vector>

namespace noosh24 {

template <class T>
struct Page {
    std::vector<T> items{};
    std::int64_t total = 0;
    std::int64_t limit = 0;
    std::int64_t offset = 0;

    [[nodiscard]] bool has_more() const noexcept
    {
        return !items.empty() && offset + static_cast<std::int64_t>(items.size()) < total;
    }
    [[nodiscard]] std::int64_t next_offset() const noexcept
    {
        return offset + static_cast<std::int64_t>(items.size());
    }
    [[nodiscard]] std::size_t size() const noexcept { return items.size(); }
    [[nodiscard]] bool empty() const noexcept { return items.empty(); }
    auto begin() noexcept { return items.begin(); }
    auto end() noexcept { return items.end(); }
    auto begin() const noexcept { return items.begin(); }
    auto end() const noexcept { return items.end(); }
};

template <class T>
class ItemRange {
public:
    using Fetch = std::function<Page<T>(std::int64_t offset)>;

private:
    struct State {
        Fetch fetch;
        std::int64_t start = 0;
        Page<T> page;
        std::size_t index = 0;
        bool started = false;
        bool done = false;

        void load(std::int64_t offset)
        {
            page = fetch(offset);
            index = 0;
            done = page.items.empty();
        }

        void advance()
        {
            if (done) {
                return;
            }
            ++index;
            if (index < page.items.size()) {
                return;
            }
            if (!page.has_more()) {
                done = true;
                return;
            }
            load(page.next_offset());
        }
    };

public:
    class iterator {
    public:
        using value_type = T;
        using difference_type = std::ptrdiff_t;
        using reference = T&;
        using pointer = T*;
        using iterator_concept = std::input_iterator_tag;
        using iterator_category = std::input_iterator_tag;

        iterator() = default;

        reference operator*() const { return state_->page.items[state_->index]; }
        pointer operator->() const { return &state_->page.items[state_->index]; }
        iterator& operator++()
        {
            state_->advance();
            return *this;
        }
        void operator++(int) { state_->advance(); }

        friend bool operator==(const iterator& it, std::default_sentinel_t) noexcept
        {
            return it.state_ == nullptr || it.state_->done;
        }

    private:
        friend class ItemRange;
        explicit iterator(State* state) noexcept : state_{state} {}

        State* state_ = nullptr;
    };

    ItemRange(std::int64_t start, Fetch fetch) : state_{std::make_unique<State>()}
    {
        state_->fetch = std::move(fetch);
        state_->start = start;
    }

    iterator begin()
    {
        if (!state_->started) {
            state_->started = true;
            state_->load(state_->start);
        }
        return iterator{state_.get()};
    }

    std::default_sentinel_t end() const noexcept { return {}; }

private:
    std::unique_ptr<State> state_{};
};

}
