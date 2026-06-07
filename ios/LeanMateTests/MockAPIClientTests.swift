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

    func testProfileIncompleteScenarioBecomesCompletedAfterSave() async throws {
        let client = MockAPIClient(scenario: .profileIncomplete, delayNanoseconds: 0)

        _ = try await client.saveProfile(
            SaveUserProfileRequest(
                gender: .female,
                age: 30,
                heightCm: 168,
                currentWeightKg: 62,
                targetWeightKg: 56,
                activityLevel: .light,
                timezone: "Asia/Shanghai",
                targetDate: nil
            )
        )

        let profile = try await client.profile()
        let home = try await client.todayHome(date: nil)
        let user = try await client.currentUser()

        XCTAssertTrue(profile.profileCompleted)
        XCTAssertNotNil(profile.profile)
        XCTAssertTrue(home.profileCompleted)
        XCTAssertTrue(user.profileCompleted)
    }

    func testRecognitionFailureScenarioReturnsFailedTask() async throws {
        let client = MockAPIClient(scenario: .recognitionFailed, delayNanoseconds: 0)

        let task = try await client.recognitionTask(id: MockData.taskId)

        XCTAssertEqual(task.status, .failed)
        XCTAssertNil(task.draftEntry)
        XCTAssertEqual(task.errorCode, "AI_RECOGNITION_FAILED")
    }
}
