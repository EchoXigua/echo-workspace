import XCTest
@testable import LeanMate

final class MockAPIClientTests: XCTestCase {
    func testSuccessScenarioReturnsTodayHome() async throws {
        let client = MockAPIClient(delayNanoseconds: 0)

        let home = try await client.todayHome(date: nil)

        XCTAssertTrue(home.profileCompleted)
        XCTAssertEqual(home.remainingCaloriesKcal, 863)
        XCTAssertEqual(home.foodEntries.count, 1)
    }

    func testEmptyScenarioReturnsEmptyHomeAndNoDietEntries() async throws {
        let client = MockAPIClient(scenario: .empty, delayNanoseconds: 0)

        let home = try await client.todayHome(date: nil)
        let entries = try await client.dietEntries(date: MockData.today)

        XCTAssertEqual(home.caloriesInKcal, 0)
        XCTAssertTrue(home.foodEntries.isEmpty)
        XCTAssertTrue(entries.isEmpty)
    }

    func testProfileIncompleteScenarioReturnsNilProfile() async throws {
        let client = MockAPIClient(scenario: .profileIncomplete, delayNanoseconds: 0)

        let payload = try await client.profile()

        XCTAssertFalse(payload.profileCompleted)
        XCTAssertNil(payload.profile)
    }

    func testRecognitionFailureScenarioReturnsFailedTask() async throws {
        let client = MockAPIClient(scenario: .recognitionFailed, delayNanoseconds: 0)

        let task = try await client.recognitionTask(id: MockData.taskId)

        XCTAssertEqual(task.status, .failed)
        XCTAssertNil(task.draftEntry)
        XCTAssertEqual(task.errorCode, "AI_RECOGNITION_FAILED")
    }
}
