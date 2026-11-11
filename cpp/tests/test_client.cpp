#include "mock.hpp"

using namespace std::chrono_literals;
using testing_support::ClientTest;
using testing_support::has_header;
using testing_support::header;
using testing_support::json;

namespace {

const std::string agent = "noosh24-cpp/" + std::string(noosh24::version);

}

TEST_F(ClientTest, SendsKeyAndHeadersToDefaultBaseUrl)
{
    auto client = make();
    http->reply(200, {{"data",
                       {{"restaurant", {{"id", "r1"}, {"name", "Masago"}, {"slug", "masago"}}},
                        {"key",
                         {{"id", "k1"},
                          {"name", "Wolt"},
                          {"prefix", "nsk_Ab3dE9xQ"},
                          {"scopes", {"menu:read", "orders:read"}}}},
                        {"subscription", {{"status", "active"}, {"modules", {"loyalty"}}}},
                        {"features", {{"loyalty", true}, {"inventory", false}}}}}});

    auto me = client.whoami();

    const auto& request = http->last();
    EXPECT_EQ(request.method, "GET");
    EXPECT_EQ(request.url, "https://open-api.noosh24.com/v1/whoami");
    EXPECT_EQ(header(request, "authorization"), "Bearer nsk_test_123");
    EXPECT_EQ(header(request, "accept"), "application/json");
    EXPECT_EQ(header(request, "user-agent"), agent);
    EXPECT_FALSE(request.body.has_value());
    EXPECT_FALSE(has_header(request, "content-type"));
    EXPECT_EQ(request.timeout, 30s);
    EXPECT_EQ(me.restaurant->name, "Masago");
    EXPECT_EQ(me.key->scopes, (std::vector<std::string>{"menu:read", "orders:read"}));
    EXPECT_EQ(me.subscription->status, "active");
    EXPECT_EQ(me.features->loyalty, true);
    EXPECT_EQ(me.features->inventory, false);
}

TEST_F(ClientTest, CustomBaseUrlTimeoutAndUserAgent)
{
    auto client = make({.base_url = "http://localhost:8080/v1/", .timeout = 5s, .user_agent = "acme-pos/2.1"});
    http->reply(200, {{"data", json::object()}});

    (void)client.whoami();

    EXPECT_EQ(http->last().url, "http://localhost:8080/v1/whoami");
    EXPECT_EQ(header(http->last(), "user-agent"), "acme-pos/2.1 " + agent);
    EXPECT_EQ(http->last().timeout, 5s);
}

TEST(Client, RejectsEmptyKey)
{
    EXPECT_THROW(noosh24::Client{"  "}, std::invalid_argument);
    EXPECT_THROW(noosh24::Client{""}, std::invalid_argument);
    EXPECT_THROW(noosh24::Client{static_cast<const char*>(nullptr)}, std::invalid_argument);
    EXPECT_THROW(noosh24::Client{std::string("\t\n")}, std::invalid_argument);
}

TEST_F(ClientTest, ClientIsMovable)
{
    auto first = make();
    noosh24::Client second = std::move(first);
    http->reply(200, {{"data", {{"items", json::array()}, {"total", 0}}}});

    EXPECT_TRUE(second.tables().list().empty());
}

TEST_F(ClientTest, RetriesRateLimitAfterRetryAfter)
{
    auto client = make();
    http->reply(429, {{"error", "rate_limit_exceeded"}, {"message", "slow down"}}, {{"Retry-After", "3"}});
    http->reply(200, {{"data", {{"items", json::array()}, {"total", 0}}}});

    EXPECT_TRUE(client.tables().list().empty());
    EXPECT_EQ(http->requests.size(), 2U);
    EXPECT_EQ(sleeps, (std::vector<std::chrono::milliseconds>{3s}));
}

TEST_F(ClientTest, GivesUpAfterMaxRetries)
{
    auto client = make({.max_retries = 1});
    http->reply(429, {{"error", "rate_limit_exceeded"}, {"message", "slow down"}}, {{"Retry-After", "1"}});
    http->reply(429, {{"error", "rate_limit_exceeded"}, {"message", "slow down"}}, {{"Retry-After", "7"}});

    try {
        (void)client.tables().list();
        FAIL() << "expected RateLimitError";
    } catch (const noosh24::RateLimitError& error) {
        EXPECT_EQ(error.status(), 429);
        EXPECT_EQ(error.code(), "rate_limit_exceeded");
        EXPECT_EQ(error.retry_after(), 7);
        EXPECT_STREQ(error.what(), "slow down");
        EXPECT_EQ(error.headers().at("retry-after"), "7");
    }
    EXPECT_EQ(http->requests.size(), 2U);
}

TEST_F(ClientTest, DoesNotWaitLongerThanAMinute)
{
    auto client = make();
    http->reply(429, {{"error", "rate_limit_exceeded"}}, {{"Retry-After", "120"}});

    EXPECT_THROW((void)client.tables().list(), noosh24::RateLimitError);
    EXPECT_EQ(http->requests.size(), 1U);
    EXPECT_TRUE(sleeps.empty());
}

TEST_F(ClientTest, BacksOffOnTemporarilyUnavailable)
{
    auto client = make();
    for (int i = 0; i < 3; ++i) {
        http->reply(503, {{"error", "temporarily_unavailable"}, {"message", "try again"}});
    }

    EXPECT_THROW((void)client.tables().list_halls(), noosh24::TemporarilyUnavailableError);
    EXPECT_EQ(http->requests.size(), 3U);
    EXPECT_EQ(sleeps, (std::vector<std::chrono::milliseconds>{500ms, 1000ms}));
}

TEST_F(ClientTest, RetryAfterThatIsNotANumberFallsBackToBackoff)
{
    auto client = make({.max_retries = 1});
    http->reply(502, {{"error", "bad_gateway"}}, {{"retry-after", "Wed, 21 Oct 2026 07:28:00 GMT"}});
    http->reply(200, {{"data", {{"items", json::array()}, {"total", 0}}}});

    EXPECT_TRUE(client.tables().list().empty());
    EXPECT_EQ(sleeps, (std::vector<std::chrono::milliseconds>{500ms}));
}

TEST_F(ClientTest, RetriesConnectionErrorsOnReads)
{
    auto client = make({.max_retries = 1});
    http->fail(noosh24::ConnectionError("connection reset"));
    http->reply(200, {{"data", {{"items", {{{"id", "h1"}, {"name", "Main"}, {"position", 1}}}}, {"total", 1}}}});

    EXPECT_EQ(client.tables().list_halls().at(0).name, "Main");

    http->fail(noosh24::ConnectionError("connection reset")).fail(noosh24::ConnectionError("connection reset"));
    try {
        (void)client.tables().list_halls();
        FAIL() << "expected ConnectionError";
    } catch (const noosh24::ConnectionError& error) {
        EXPECT_NE(std::string(error.what()).find("connection reset"), std::string::npos);
    }
    EXPECT_EQ(sleeps, (std::vector<std::chrono::milliseconds>{500ms, 500ms}));
}

TEST_F(ClientTest, Timeout)
{
    auto client = make({.max_retries = 0});
    http->fail(noosh24::TimeoutError("Request timed out after 30 s"));

    EXPECT_THROW((void)client.whoami(), noosh24::TimeoutError);

    http->fail(noosh24::TimeoutError("Request timed out after 30 s"));
    EXPECT_THROW((void)client.whoami(), noosh24::ConnectionError);
}

TEST_F(ClientTest, BodyThatIsNotJsonIsAnApiError)
{
    auto client = make();
    http->raw(200, "<html>gateway</html>");

    try {
        (void)client.whoami();
        FAIL() << "expected ApiError";
    } catch (const noosh24::ApiError& error) {
        EXPECT_EQ(typeid(error), typeid(noosh24::ApiError));
        EXPECT_EQ(error.status(), 200);
        EXPECT_FALSE(error.code().has_value());
        EXPECT_EQ(error.body(), "<html>gateway</html>");
    }
}

TEST_F(ClientTest, BodyWithoutDataIsAnApiError)
{
    auto client = make();
    http->reply(200, {{"items", json::array()}});

    EXPECT_THROW((void)client.whoami(), noosh24::ApiError);
}

TEST_F(ClientTest, BuildsRepeatedQueryParameters)
{
    auto client = make();
    http->reply(200, testing_support::page(json::array(), 0));

    (void)client.orders().list({.sort = {"price desc", "name asc"}, .where = "a = 1"});

    EXPECT_EQ(http->last().url,
              "https://open-api.noosh24.com/v1/orders?sort=price%20desc&sort=name%20asc&where=a%20%3D%201");
}

TEST_F(ClientTest, ErrorsAreNoosh24Errors)
{
    auto client = make({.max_retries = 0});
    http->reply(500, {{"error", "query_failed"}});

    EXPECT_THROW((void)client.whoami(), noosh24::Error);
}
