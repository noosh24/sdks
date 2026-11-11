import Foundation
import Noosh24
import Testing

@Suite struct WhereTests {
    @Test func buildsAndOnlyConditions() throws {
        let baku = try #require(TimeZone(secondsFromGMT: 4 * 3600))
        let text = try Where()
            .eq("category", "Salads")
            .ne("station", "")
            .gt("price", 4.75)
            .lte("prepMinutes", 15)
            .eq("vegetarian", false)
            .gte("createdAt", ZonedDateTime(Date(timeIntervalSince1970: 1_793_541_600), in: baku))
            .lt("price", 20.0)
            .in("id", ["7f0c", "O'Neil", 3])
            .description

        #expect(
            text
                == "category = 'Salads' AND station != '' AND price > 4.75 AND prepMinutes <= 15 AND vegetarian = false AND createdAt >= '2026-11-01T18:00:00+04:00' AND price < 20 AND id in ('7f0c', 'O''Neil', 3)"
        )
    }

    @Test func datesAndPlainDates() throws {
        let text = try Where()
            .lt("visitedOn", PlainDate(year: 2026, month: 11, day: 2))
            .gte("createdAt", Date(timeIntervalSince1970: 1_793_541_600))
            .lt("updatedAt", Date(timeIntervalSince1970: 1_793_541_600.25))
            .description

        #expect(text == "visitedOn < '2026-11-02' AND createdAt >= '2026-11-01T14:00:00+00:00' AND updatedAt < '2026-11-01T14:00:00.250000+00:00'")
    }

    @Test func plainDate() throws {
        let baku = try #require(TimeZone(secondsFromGMT: 4 * 3600))
        #expect(PlainDate(year: 2026, month: 1, day: 5).description == "2026-01-05")
        #expect(PlainDate(parsing: "2026-02-29") == nil)
        #expect(PlainDate(parsing: "2028-02-29")?.description == "2028-02-29")
        #expect(PlainDate(parsing: "20261120") == nil)
        #expect(PlainDate(Date(timeIntervalSince1970: 1_793_570_400), in: baku).description == "2026-11-02")
        #expect(PlainDate(Date(timeIntervalSince1970: 1_793_570_400), in: TimeZone(secondsFromGMT: 0)!).description == "2026-11-01")
    }

    @Test func emptyIsEmptyString() {
        #expect(Where().description == "")
        #expect(Where().conditions.isEmpty)
    }

    @Test func numbers() throws {
        #expect(try Where().eq("a", 20.0).eq("b", -3).eq("c", 0.1).eq("d", 1e-7).description == "a = 20 AND b = -3 AND c = 0.1 AND d = 1e-07")
    }

    @Test func rejectsBadInput() {
        #expect(throws: Noosh24Error.self) { try Where().eq("price = 1 OR 1", 1) }
        #expect(throws: Noosh24Error.self) { try Where().eq("1price", 1) }
        #expect(throws: Noosh24Error.self) { try Where().eq("", 1) }
        #expect(throws: Noosh24Error.self) { try Where().in("id", []) }
        #expect(throws: Noosh24Error.self) { try Where().gt("price", Double.nan) }
        #expect(throws: Noosh24Error.self) { try Where().gt("price", Double.infinity) }
        #expect(throws: Noosh24Error.self) { try Where().eq("name", nil as String?) }
        #expect(throws: Never.self) { try Where().eq("table.label", Optional("T5")).eq("snake_case", 1) }
    }
}
