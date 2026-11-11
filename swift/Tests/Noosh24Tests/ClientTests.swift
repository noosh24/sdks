import Foundation
import Noosh24
import Testing

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@Suite struct ClientTests {
    @Test func sendsKeyAndHeadersToDefaultBaseURL() async throws {
        let h = try Harness()
        await h.http.json(200, [
            "data": [
                "restaurant": ["id": "r1", "name": "Masago", "slug": "masago"],
                "key": ["id": "k1", "name": "Wolt", "prefix": "nsk_Ab3dE9xQ", "scopes": ["menu:read", "orders:read"]],
                "subscription": ["status": "active", "modules": ["loyalty"]],
                "features": ["loyalty": true, "inventory": false],
            ],
        ])

        let me = try await h.client.whoami()

        let request = await h.http.last
        #expect(request.method == "GET")
        #expect(request.url.absoluteString == "https://open-api.noosh24.com/v1/whoami")
        #expect(request.headers["Authorization"] == "Bearer nsk_test_123")
        #expect(request.headers["Accept"] == "application/json")
        #expect(request.headers["User-Agent"] == "noosh24-swift/" + Noosh24Client.version)
        #expect(request.headers["Content-Type"] == nil)
        #expect(request.body == nil)
        #expect(request.timeout == .seconds(30))
        #expect(me.restaurant?.name == "Masago")
        #expect(me.key?.scopes == ["menu:read", "orders:read"])
        #expect(me.subscription?.status == .active)
        #expect(me.subscription?.modules == ["loyalty"])
        #expect(me.features?.loyalty == true)
        #expect(me.features?.inventory == false)
    }

    @Test func customBaseURLAndUserAgent() async throws {
        let h = try Harness(baseURL: URL(string: "http://localhost:8080/v1/")!, userAgent: "acme-pos/2.1")
        await h.http.json(200, ["data": [:]])

        _ = try await h.client.whoami()

        let request = await h.http.last
        #expect(request.url.absoluteString == "http://localhost:8080/v1/whoami")
        #expect(request.headers["User-Agent"] == "acme-pos/2.1 noosh24-swift/" + Noosh24Client.version)
    }

    @Test func rejectsEmptyKey() {
        for key in ["", "  ", "\n"] {
            #expect(throws: Noosh24Error.self) {
                try Noosh24Client(apiKey: key)
            }
        }
    }

    @Test func defaultConfiguration() {
        let configuration = Noosh24Client.Configuration()
        #expect(configuration.baseURL.absoluteString == "https://open-api.noosh24.com/v1")
        #expect(configuration.timeout == .seconds(30))
        #expect(configuration.maxRetries == 2)
        #expect(configuration.userAgent == nil)
    }

    @Test func retriesRateLimitAfterRetryAfter() async throws {
        let h = try Harness()
        await h.http.json(429, ["error": "rate_limit_exceeded", "message": "slow down"], headers: ["Retry-After": "3"])
        await h.http.json(200, ["data": ["items": [], "total": 0]])

        let tables = try await h.client.tables.list()

        #expect(tables.isEmpty)
        #expect(await h.http.requests.count == 2)
        #expect(await h.sleeps.calls == [.seconds(3)])
    }

    @Test func givesUpAfterMaxRetries() async throws {
        let h = try Harness(maxRetries: 1)
        await h.http.json(429, ["error": "rate_limit_exceeded", "message": "slow down"], headers: ["Retry-After": "1"])
        await h.http.json(429, ["error": "rate_limit_exceeded", "message": "slow down"], headers: ["Retry-After": "7"])

        let error = await failure { try await h.client.tables.list() }

        let api = try #require(error.flatMap(apiError))
        #expect(api.status == 429)
        #expect(api.code == .rateLimitExceeded)
        #expect(api.kind == .rateLimit)
        #expect(api.retryAfter == 7)
        #expect(api.message == "slow down")
        #expect(api.headers["retry-after"] == "7")
        #expect((error as? Noosh24Error)?.message == "slow down")
        #expect(await h.http.requests.count == 2)
        #expect(await h.sleeps.calls == [.seconds(1)])
    }

    @Test func doesNotWaitLongerThanAMinute() async throws {
        let h = try Harness()
        await h.http.json(429, ["error": "rate_limit_exceeded"], headers: ["Retry-After": "120"])

        let error = await failure { try await h.client.tables.list() }

        #expect(error.flatMap(apiError)?.code == .rateLimitExceeded)
        #expect(error.flatMap(apiError)?.retryAfter == 120)
        #expect(await h.http.requests.count == 1)
        #expect(await h.sleeps.calls.isEmpty)
    }

    @Test func backsOffOnTemporarilyUnavailable() async throws {
        let h = try Harness()
        for _ in 0..<3 {
            await h.http.json(503, ["error": "temporarily_unavailable", "message": "try again"])
        }

        let error = await failure { try await h.client.tables.listHalls() }

        let api = try #require(error.flatMap(apiError))
        #expect(api.code == .temporarilyUnavailable)
        #expect(api.kind == .server)
        #expect(api.retryAfter == nil)
        #expect(await h.http.requests.count == 3)
        #expect(await h.sleeps.calls == [.milliseconds(500), .seconds(1)])
    }

    @Test func retriesConnectionErrorsOnReads() async throws {
        let h = try Harness(maxRetries: 1)
        await h.http.fail(Boom(description: "connection reset"))
        await h.http.json(200, ["data": ["items": [["id": "h1", "name": "Main", "position": 1]], "total": 1]])

        let halls = try await h.client.tables.listHalls()
        #expect(halls.first?.name == "Main")
        #expect(halls.first?.position == 1)

        await h.http.fail(Boom(description: "connection reset"))
        await h.http.fail(URLError(.networkConnectionLost))
        let error = await failure { try await h.client.tables.listHalls() }

        let failure = try #require(error as? Noosh24Error)
        guard case .connection(let message, let underlying) = failure else {
            Issue.record("expected a connection error, got \(failure)")
            return
        }
        #expect(message.hasPrefix("Could not reach the Noosh24 API: "))
        #expect(underlying is URLError)
        #expect(failure.isConnectionError)
        #expect(!failure.isTimeout)
        #expect(await h.http.requests.count == 4)
        #expect(await h.sleeps.calls == [.milliseconds(500), .milliseconds(500)])
    }

    @Test func timeout() async throws {
        let h = try Harness(maxRetries: 0)
        await h.http.fail(URLError(.timedOut))

        let error = await failure { try await h.client.whoami() }

        let failure = try #require(error as? Noosh24Error)
        guard case .timeout(let message) = failure else {
            Issue.record("expected a timeout, got \(failure)")
            return
        }
        #expect(message == "Request timed out after 30 s")
        #expect(failure.isConnectionError)
        #expect(failure.isTimeout)
    }

    @Test func timeoutsAreRetried() async throws {
        let h = try Harness(maxRetries: 2)
        await h.http.fail(URLError(.timedOut))
        await h.http.fail(Noosh24Error.timeout(message: "custom transport timed out"))
        await h.http.json(200, ["data": ["restaurant": ["name": "Masago"]]])

        #expect(try await h.client.whoami().restaurant?.name == "Masago")
        #expect(await h.sleeps.calls == [.milliseconds(500), .seconds(1)])
    }

    @Test func cancellationIsNotRetried() async throws {
        let h = try Harness()
        await h.http.fail(CancellationError())

        let error = await failure { try await h.client.whoami() }

        #expect(error is CancellationError)
        #expect(await h.http.requests.count == 1)
    }

    @Test func bodyThatIsNotJSONIsAnAPIError() async throws {
        let h = try Harness()
        await h.http.raw(200, "<html>gateway</html>")

        let error = await failure { try await h.client.whoami() }

        let api = try #require(error.flatMap(apiError))
        #expect(api.status == 200)
        #expect(api.code == nil)
        #expect(api.kind == .other)
        #expect(api.body == "<html>gateway</html>")
    }

    @Test func bodyWithoutDataIsAnAPIError() async throws {
        let h = try Harness()
        await h.http.json(200, ["items": []])

        let error = await failure { try await h.client.tables.list() }

        #expect(error.flatMap(apiError)?.message == "The API answered without a \"data\" field")
    }

    @Test func nonJSONErrorBodyFallsBackToStatus() async throws {
        let h = try Harness(maxRetries: 0)
        await h.http.raw(502, "<html>bad gateway</html>")

        let error = await failure { try await h.client.whoami() }

        let api = try #require(error.flatMap(apiError))
        #expect(api.status == 502)
        #expect(api.message == "HTTP 502")
        #expect(api.kind == .server)
    }

    @Test func buildsRepeatedQueryParameters() async throws {
        let h = try Harness()
        await h.http.json(200, page([], 0))

        _ = try await h.client.orders.list(sort: ["price desc", "name asc"], where: "a = 1")

        let request = await h.http.last
        #expect(request.url.query == "sort=price%20desc&sort=name%20asc&where=a%20%3D%201")
        #expect(query(request) == ["sort": ["price desc", "name asc"], "where": ["a = 1"]])
    }

    @Test func emptySortAndWhereAreOmitted() async throws {
        let h = try Harness()
        await h.http.json(200, page([], 0))

        _ = try await h.client.orders.list(sort: "", where: Where())

        #expect(await h.http.last.url.query == nil)
    }
}
