import Foundation
import Noosh24
import Testing

struct ErrorCase: Sendable, CustomTestStringConvertible {
    let status: Int
    let code: String?
    let expected: Noosh24ErrorCode?
    let kind: Noosh24APIError.Kind

    var testDescription: String {
        "\(status) \(code ?? "none")"
    }
}

let errorCases: [ErrorCase] = [
    ErrorCase(status: 400, code: "validation_error", expected: .validationError, kind: .validation),
    ErrorCase(status: 401, code: "no_api_key", expected: .noApiKey, kind: .authentication),
    ErrorCase(status: 401, code: "invalid_api_key", expected: .invalidApiKey, kind: .authentication),
    ErrorCase(status: 403, code: "insufficient_scope", expected: .insufficientScope, kind: .permissionDenied),
    ErrorCase(status: 403, code: "module_not_enabled", expected: .moduleNotEnabled, kind: .permissionDenied),
    ErrorCase(status: 403, code: "venue_suspended", expected: .venueSuspended, kind: .permissionDenied),
    ErrorCase(status: 403, code: "not_your_reservation", expected: .notYourReservation, kind: .permissionDenied),
    ErrorCase(status: 404, code: "not_found", expected: .notFound, kind: .notFound),
    ErrorCase(status: 404, code: "table_not_found", expected: .tableNotFound, kind: .notFound),
    ErrorCase(status: 409, code: "table_taken", expected: .tableTaken, kind: .conflict),
    ErrorCase(status: 409, code: "cannot_cancel", expected: .cannotCancel, kind: .conflict),
    ErrorCase(status: 422, code: "outside_hours", expected: .outsideHours, kind: .unprocessable),
    ErrorCase(status: 422, code: "in_the_past", expected: .inThePast, kind: .unprocessable),
    ErrorCase(status: 422, code: "table_too_small", expected: .tableTooSmall, kind: .unprocessable),
    ErrorCase(status: 429, code: "rate_limit_exceeded", expected: .rateLimitExceeded, kind: .rateLimit),
    ErrorCase(status: 503, code: "temporarily_unavailable", expected: .temporarilyUnavailable, kind: .server),
    ErrorCase(status: 403, code: "something_new", expected: .unknown("something_new"), kind: .permissionDenied),
    ErrorCase(status: 409, code: "something_new", expected: .unknown("something_new"), kind: .conflict),
    ErrorCase(status: 500, code: "query_failed", expected: .unknown("query_failed"), kind: .server),
    ErrorCase(status: 418, code: nil, expected: nil, kind: .other),
]

@Suite struct ErrorTests {
    @Test(arguments: errorCases)
    func mapsErrorCodes(_ c: ErrorCase) async throws {
        let h = try Harness(maxRetries: 0)
        await h.http.json(c.status, c.code.map { ["error": .string($0), "message": "Mesaj"] } ?? ["nope": true])

        let error = await failure { try await h.client.customers.get("c1") }

        let api = try #require(error.flatMap(apiError))
        #expect(api.status == c.status)
        #expect(api.code == c.expected)
        #expect(api.code?.rawValue == c.code)
        #expect(api.kind == c.kind)
        #expect(api.message == (c.code == nil ? "HTTP \(c.status)" : "Mesaj"))
        #expect(api.headers["content-type"] == "application/json")
    }

    @Test func codeWinsOverStatus() {
        let error = Noosh24APIError(status: 400, code: .tableTaken, message: "x", headers: ["Retry-After": "2"])
        #expect(error.kind == .conflict)
        #expect(error.headers == ["retry-after": "2"])
        #expect(error.retryAfter == 2)
    }

    @Test func everyCodeRoundTrips() {
        #expect(Noosh24ErrorCode.allCases.count == 16)
        for code in Noosh24ErrorCode.allCases {
            #expect(Noosh24ErrorCode(rawValue: code.rawValue) == code)
            #expect(code.kind != nil)
        }
        #expect(Noosh24ErrorCode(rawValue: "brand_new") == .unknown("brand_new"))
        #expect(Noosh24ErrorCode.unknown("brand_new").kind == nil)
    }

    @Test func retryAfterParsing() {
        func make(_ value: String?) -> Noosh24APIError {
            Noosh24APIError(status: 429, code: .rateLimitExceeded, message: "x", headers: value.map { ["retry-after": $0] } ?? [:])
        }
        #expect(make(nil).retryAfter == nil)
        #expect(make("5").retryAfter == 5)
        #expect(make("2.9").retryAfter == 2)
        #expect(make("-3").retryAfter == 0)
        #expect(make("Wed, 21 Oct 2026 07:28:00 GMT").retryAfter == nil)
    }

    @Test func validationErrorIsNotRetried() async throws {
        let h = try Harness()
        await h.http.json(400, ["error": "validation_error", "message": "\"nope\" is not a filterable field on this resource"])

        let error = await failure { try await h.client.menu.listProducts(where: "nope = 1") }

        let api = try #require(error.flatMap(apiError))
        #expect(api.code == .validationError)
        #expect(api.message.contains("not a filterable field"))
        #expect(await h.http.requests.count == 1)
    }

    @Test func catchesByCodeAndKind() async throws {
        let h = try Harness(maxRetries: 0)
        await h.http.json(409, ["error": "table_taken", "message": "taken"])
        await h.http.json(422, ["error": "in_the_past", "message": "past"])

        var caught: [String] = []
        do {
            _ = try await h.client.reservations.get("r1")
        } catch let error as Noosh24Error where error.code == .tableTaken {
            caught.append("tableTaken")
        }
        do {
            _ = try await h.client.reservations.get("r1")
        } catch let error as Noosh24Error where error.kind == .unprocessable {
            caught.append("unprocessable")
        }
        #expect(caught == ["tableTaken", "unprocessable"])
    }
}
