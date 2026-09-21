import UIKit
import XCTest
@testable import GoodWalk

/// A photo now belongs to the walk it was taken on, so it has to appear on the calendar, survive
/// until the walk does, and go when the walk goes. Nothing here leaves the phone.
@MainActor
final class WalkPhotoTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "goodwalk.tests.walkphotos"

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suite)
        defaults = UserDefaults(suiteName: suite)
    }

    private func makeState() -> AppState {
        let state = AppState(defaults: defaults, tracker: MockDistanceTracker())
        state.dog.name = "Rex"
        state.dog.goalMinutes = 60
        return state
    }

    /// A small solid image; the store only cares that it can be encoded as a JPEG.
    private func image(_ color: UIColor = .orange) -> UIImage {
        let size = CGSize(width: 40, height: 30)
        return UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    func testAWalkStartsWithNoPhoto() {
        let state = makeState()
        let walk = state.quickLog(minutes: 30, source: .quickLog)
        XCTAssertFalse(walk.hasPhoto)
        XCTAssertNil(state.walkPhoto(for: walk.id))
    }

    func testSavingAPhotoMarksTheWalkAndReadsBack() {
        let state = makeState()
        let walk = state.quickLog(minutes: 30, source: .quickLog)
        state.setWalkPhoto(image(), for: walk.id)

        XCTAssertTrue(state.walks.first { $0.id == walk.id }?.hasPhoto ?? false)
        XCTAssertNotNil(state.walkPhoto(for: walk.id), "the photo has to come back after the app is closed")
        XCTAssertNotNil(state.walkThumb(for: walk.id))
        state.removeWalkPhoto(for: walk.id)
    }

    func testThePhotoOutlivesTheAppButNotTheWalk() {
        let state = makeState()
        let walk = state.quickLog(minutes: 30, source: .quickLog)
        state.setWalkPhoto(image(), for: walk.id)

        // Relaunch: the flag is persisted with the walk and the file is still on disk.
        let relaunched = AppState(defaults: defaults, tracker: MockDistanceTracker())
        XCTAssertTrue(relaunched.walks.first { $0.id == walk.id }?.hasPhoto ?? false)
        XCTAssertNotNil(relaunched.walkPhoto(for: walk.id))

        relaunched.delete(walk)
        XCTAssertNil(relaunched.walkPhoto(for: walk.id), "deleting the walk deletes its photo")
        XCTAssertFalse(WalkPhotoStore.exists(for: walk.id))
    }

    func testRemovingThePhotoLeavesTheWalk() {
        let state = makeState()
        let walk = state.quickLog(minutes: 30, source: .quickLog)
        state.setWalkPhoto(image(), for: walk.id)
        state.removeWalkPhoto(for: walk.id)

        XCTAssertFalse(state.walks.first { $0.id == walk.id }?.hasPhoto ?? true)
        XCTAssertNil(state.walkPhoto(for: walk.id))
        XCTAssertEqual(state.walks.count, 1, "the walk itself stays; only the picture went")
    }

    func testRemovingADogTakesTheirSoloWalksPhotoWithIt() {
        let state = makeState()
        var juno = DogProfile()
        juno.name = "Juno"
        let junoID = state.addDog(juno).id
        let solo = state.quickLog(minutes: 20, source: .quickLog, dogIDs: [junoID])
        state.setWalkPhoto(image(), for: solo.id)

        state.removeDog(junoID)
        XCTAssertFalse(WalkPhotoStore.exists(for: solo.id))
    }

    func testTheDayListFindsThatDaysWalksNewestFirst() {
        let state = makeState()
        let morning = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
        let evening = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
        state.quickLog(minutes: 20, source: .quickLog, at: morning)
        state.quickLog(minutes: 30, source: .quickLog, at: evening)

        let today = state.walks(on: Date())
        XCTAssertEqual(today.count, 2)
        XCTAssertEqual(today.first?.minutes, 30, "the evening walk is on top")
    }

    func testTheMonthGridKnowsWhichDaysHaveAPhoto() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var withPhoto = Walk(start: cal.date(byAdding: .hour, value: 9, to: today)!, minutes: 30,
                             distanceMeters: 1_000, distanceEstimated: true, source: .timer)
        withPhoto.hasPhoto = true
        let without = Walk(start: cal.date(byAdding: .hour, value: 18, to: today)!, minutes: 20,
                           distanceMeters: 800, distanceEstimated: true, source: .quickLog)

        let summary = MonthSummary.build(walks: [withPhoto, without], goalMinutes: 60, month: today)
        let day = summary.days.first { $0.date.map { cal.isDate($0, inSameDayAs: today) } ?? false }
        XCTAssertEqual(day?.walkCount, 2)
        XCTAssertTrue(day?.hasPhoto ?? false)

        let other = summary.days.first { cell in
            guard let date = cell.date else { return false }
            return !cal.isDate(date, inSameDayAs: today)
        }
        XCTAssertFalse(other?.hasPhoto ?? true)
        XCTAssertEqual(other?.walkCount, 0)
    }
}
