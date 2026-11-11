#include <functional>
#include <optional>
#include <typeindex>

#include "mock.hpp"

using testing_support::ClientTest;
using testing_support::json;

namespace {

struct Case {
    int status;
    std::optional<std::string> code;
    std::type_index type;
    std::function<bool(const std::exception*)> parent;
};

template <class P>
std::function<bool(const std::exception*)> is()
{
    return [](const std::exception* error) { return dynamic_cast<const P*>(error) != nullptr; };
}

template <class T>
std::type_index type()
{
    return std::type_index(typeid(T));
}

}

TEST_F(ClientTest, MapsErrorCodes)
{
    using namespace noosh24;
    const std::vector<Case> cases{
        {400, "validation_error", type<ValidationError>(), is<ApiError>()},
        {401, "no_api_key", type<NoApiKeyError>(), is<AuthenticationError>()},
        {401, "invalid_api_key", type<InvalidApiKeyError>(), is<AuthenticationError>()},
        {403, "insufficient_scope", type<InsufficientScopeError>(), is<PermissionDeniedError>()},
        {403, "module_not_enabled", type<ModuleNotEnabledError>(), is<PermissionDeniedError>()},
        {403, "venue_suspended", type<VenueSuspendedError>(), is<PermissionDeniedError>()},
        {403, "not_your_reservation", type<NotYourReservationError>(), is<PermissionDeniedError>()},
        {404, "not_found", type<NotFoundError>(), is<ApiError>()},
        {404, "table_not_found", type<TableNotFoundError>(), is<NotFoundError>()},
        {409, "table_taken", type<TableTakenError>(), is<ConflictError>()},
        {409, "cannot_cancel", type<CannotCancelError>(), is<ConflictError>()},
        {422, "outside_hours", type<OutsideHoursError>(), is<UnprocessableError>()},
        {422, "in_the_past", type<InThePastError>(), is<UnprocessableError>()},
        {422, "table_too_small", type<TableTooSmallError>(), is<UnprocessableError>()},
        {429, "rate_limit_exceeded", type<RateLimitError>(), is<ApiError>()},
        {503, "temporarily_unavailable", type<TemporarilyUnavailableError>(), is<ServerError>()},
        {403, "something_new", type<PermissionDeniedError>(), is<ApiError>()},
        {409, "something_new", type<ConflictError>(), is<ApiError>()},
        {500, "query_failed", type<ServerError>(), is<ApiError>()},
        {418, std::nullopt, type<ApiError>(), is<Error>()},
    };
    auto client = make({.max_retries = 0});
    for (const auto& c : cases) {
        SCOPED_TRACE(std::to_string(c.status) + " " + c.code.value_or("<none>"));
        http->reply(c.status, c.code ? json{{"error", *c.code}, {"message", "Mesaj"}} : json{{"nope", true}});
        try {
            (void)client.customers().get("c1");
            ADD_FAILURE() << "expected an ApiError";
        } catch (const ApiError& error) {
            EXPECT_EQ(std::type_index(typeid(error)), c.type);
            const std::exception* thrown = &error;
            EXPECT_TRUE(c.parent(thrown));
            EXPECT_TRUE(is<Error>()(thrown));
            EXPECT_EQ(error.status(), c.status);
            EXPECT_EQ(error.code(), c.code);
            EXPECT_EQ(error.message(), c.code ? "Mesaj" : "HTTP " + std::to_string(c.status));
            EXPECT_EQ(std::string(error.what()), error.message());
        }
    }
}

TEST_F(ClientTest, MissingMessageFallsBackToCode)
{
    auto client = make({.max_retries = 0});
    http->reply(404, {{"error", "not_found"}});

    try {
        (void)client.customers().get("c1");
        FAIL() << "expected NotFoundError";
    } catch (const noosh24::NotFoundError& error) {
        EXPECT_EQ(error.message(), "not_found");
    }
}

TEST_F(ClientTest, ValidationErrorIsNotRetried)
{
    auto client = make();
    http->reply(400, {{"error", "validation_error"}, {"message", "\"nope\" is not a filterable field on this resource"}});

    try {
        (void)client.menu().list_products({.where = "nope = 1"});
        FAIL() << "expected ValidationError";
    } catch (const noosh24::ValidationError& error) {
        EXPECT_NE(error.message().find("not a filterable field"), std::string::npos);
    }
    EXPECT_EQ(http->requests.size(), 1U);
}

TEST(Errors, RetryAfterIsReadFromHeaders)
{
    EXPECT_EQ(noosh24::RateLimitError(429, "rate_limit_exceeded", "m", {{"Retry-After", "12"}}).retry_after(), 12);
    EXPECT_EQ(noosh24::RateLimitError(429, "rate_limit_exceeded", "m", {{"retry-after", "2.9"}}).retry_after(), 2);
    EXPECT_EQ(noosh24::RateLimitError(429, "rate_limit_exceeded", "m", {{"retry-after", "-4"}}).retry_after(), 0);
    EXPECT_EQ(noosh24::RateLimitError(429, "rate_limit_exceeded", "m", {{"retry-after", "soon"}}).retry_after(),
              std::nullopt);
    EXPECT_EQ(noosh24::RateLimitError(429, "rate_limit_exceeded", "m").retry_after(), std::nullopt);
}
