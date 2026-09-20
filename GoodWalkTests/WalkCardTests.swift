import XCTest
@testable import GoodWalk

/// The end-of-walk card's words. The card itself is a view; these are the strings it puts on it.
final class WalkCardTests: XCTestCase {
    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func walk(minutes: Int, meters: Double, daysAgo: Int = 0) -> Walk {
        let start = cal.date(byAdding: .day, value: -daysAgo, to: Date())!
        return Walk(start: start, minutes: minutes, distanceMeters: meters,
                    distanceEstimated: false, source: .timer)
    }

    func testHeadlineReadsAsMinutesWithTheDog() {
        XCTAssertEqual(ShareCardView.headline(minutes: 42, dog: "Rex"), "42 minutes with Rex")
        XCTAssertEqual(ShareCardView.headline(minutes: 1, dog: "Rex"), "1 minute with Rex")
        XCTAssertEqual(ShareCardView.headline(minutes: 59, dog: "Rex"), "59 minutes with Rex")
        XCTAssertEqual(ShareCardView.headline(minutes: 90, dog: "Rex"), "1h 30m with Rex")
        XCTAssertEqual(ShareCardView.headline(minutes: 60, dog: "Bo"), "1h with Bo")
    }

    func testDetailPluralisesMilesAndSaysToday() {
        let d = ShareCardView.detail(walk: walk(minutes: 42, meters: WalkPlan.metersPerMile * 1.8), calendar: cal)
        XCTAssertEqual(d, "1.8 miles · today")
    }

    func testDetailUsesSingularMileWithoutADecimal() {
        let d = ShareCardView.detail(walk: walk(minutes: 20, meters: WalkPlan.metersPerMile), calendar: cal)
        XCTAssertTrue(d.hasPrefix("1 mile ·"), d)
        XCTAssertFalse(d.contains("miles"), d)
        XCTAssertFalse(d.contains("1.0"), d)
    }

    func testMilesPhrase() {
        XCTAssertEqual(Stats.milesPhrase(1), "1 mile")
        XCTAssertEqual(Stats.milesPhrase(1.04), "1 mile")
        XCTAssertEqual(Stats.milesPhrase(0.6), "0.6 miles")
        XCTAssertEqual(Stats.milesPhrase(1.8), "1.8 miles")
        XCTAssertEqual(Stats.milesPhrase(12.4), "12 miles")
    }

    func testDetailSaysYesterday() {
        let d = ShareCardView.detail(walk: walk(minutes: 30, meters: WalkPlan.metersPerMile * 2, daysAgo: 1), calendar: cal)
        XCTAssertTrue(d.hasSuffix("· yesterday"), d)
    }

    func testDetailFallsBackToADateForOlderWalks() {
        let d = ShareCardView.detail(walk: walk(minutes: 30, meters: WalkPlan.metersPerMile * 2, daysAgo: 9), calendar: cal)
        XCTAssertFalse(d.contains("today"), d)
        XCTAssertFalse(d.contains("yesterday"), d)
    }

    func testLongWalksRoundMilesToWholeNumbers() {
        let d = ShareCardView.detail(walk: walk(minutes: 300, meters: WalkPlan.metersPerMile * 12.4), calendar: cal)
        XCTAssertTrue(d.hasPrefix("12 miles"), d)
    }
}
