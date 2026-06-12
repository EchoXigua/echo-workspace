import XCTest
@testable import LeanMate

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testSuccessLoadsHomeDataFromAPI() async {
        let viewModel = HomeViewModel(apiClient: MockAPIClient(delayNanoseconds: 0))

        await viewModel.load()

        if case .loaded(let home) = viewModel.state {
            XCTAssertEqual(home.remainingCaloriesKcal, 863)
            XCTAssertEqual(home.calorieTargetKcal, 1800)
            XCTAssertEqual(home.streakDays, 12)
            XCTAssertEqual(home.foodEntries.count, 1)
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func testEmptyScenarioDoesNotBecomeLoaded() async {
        let viewModel = HomeViewModel(apiClient: MockAPIClient(scenario: .empty, delayNanoseconds: 0))

        await viewModel.load()

        if case .empty(let home) = viewModel.state {
            XCTAssertTrue(home.foodEntries.isEmpty)
            XCTAssertEqual(home.caloriesInKcal, 0)
        } else {
            XCTFail("Expected empty state")
        }
    }

    func testProfileIncompleteScenarioRoutesToProfileIncompleteState() async {
        let viewModel = HomeViewModel(
            apiClient: MockAPIClient(scenario: .profileIncomplete, delayNanoseconds: 0)
        )

        await viewModel.load()

        if case .profileIncomplete(let home) = viewModel.state {
            XCTAssertFalse(home.profileCompleted)
            XCTAssertEqual(home.calorieTargetKcal, 0)
        } else {
            XCTFail("Expected profileIncomplete state")
        }
    }

    func testVisitorStateDoesNotCallHomeAPI() async {
        let viewModel = HomeViewModel.visitor()

        await viewModel.load()

        if case .visitor = viewModel.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected visitor state")
        }
    }

    func testVisitorWithoutLocalProfileShowsCalibrationState() async {
        let viewModel = HomeViewModel.visitor(localStore: InMemoryLocalStore())

        await viewModel.load()

        if case .profileIncomplete(let home) = viewModel.state {
            XCTAssertFalse(home.profileCompleted)
            XCTAssertEqual(home.calorieTargetKcal, 0)
        } else {
            XCTFail("Expected profileIncomplete state")
        }
    }

    func testVisitorHomeUsesLocalProfileGoal() async throws {
        let localStore = InMemoryLocalStore()
        try await localStore.saveLocalProfile(MockData.profile)
        let viewModel = HomeViewModel.visitor(localStore: localStore)

        await viewModel.load()

        if case .loaded(let home) = viewModel.state {
            XCTAssertTrue(home.profileCompleted)
            XCTAssertEqual(home.calorieTargetKcal, 1600)
            XCTAssertEqual(home.currentWeightKg, 55.8)
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func testUnauthorizedClearsTokensAndRequiresLogin() async throws {
        let tokenStore = InMemoryTokenStore()
        try await tokenStore.saveTokens(AuthTokens(accessToken: "expired", refreshToken: "refresh"))
        let viewModel = HomeViewModel(
            apiClient: MockAPIClient(scenario: .error(.unauthorized), delayNanoseconds: 0),
            tokenStore: tokenStore
        )

        await viewModel.load()
        let tokens = try await tokenStore.loadTokens()

        XCTAssertNil(tokens)
        if case .error(_, let recovery) = viewModel.state {
            XCTAssertEqual(recovery, .login)
        } else {
            XCTFail("Expected login recovery")
        }
    }

    func testMealHeaderTitleShowsStartWhenNoMealRecorded() {
        XCTAssertEqual(
            HomeMealSummaryFormatter.headerActionTitle(foodEntries: []),
            "开始记录"
        )
        XCTAssertTrue(HomeMealSummaryFormatter.hasRecordAction(foodEntries: []))
        XCTAssertNil(HomeMealSummaryFormatter.singleMissingMealType(foodEntries: []))
    }

    func testMealHeaderTitleShowsMissingMealCountWhenOnlyLunchRecorded() {
        XCTAssertEqual(
            HomeMealSummaryFormatter.headerActionTitle(foodEntries: [makeFoodEntrySummary(.lunch)]),
            "2餐可补录"
        )
        XCTAssertTrue(HomeMealSummaryFormatter.hasRecordAction(foodEntries: [makeFoodEntrySummary(.lunch)]))
        XCTAssertNil(HomeMealSummaryFormatter.singleMissingMealType(foodEntries: [makeFoodEntrySummary(.lunch)]))
    }

    func testMealHeaderTitleShowsSingleMissingMealName() {
        let entries = [
            makeFoodEntrySummary(.breakfast),
            makeFoodEntrySummary(.lunch)
        ]

        XCTAssertEqual(
            HomeMealSummaryFormatter.headerActionTitle(foodEntries: entries),
            "晚餐可补录"
        )
        XCTAssertTrue(HomeMealSummaryFormatter.hasRecordAction(foodEntries: entries))
        XCTAssertEqual(HomeMealSummaryFormatter.singleMissingMealType(foodEntries: entries), .dinner)
    }

    func testMealHeaderTitleShowsRecordedWhenBaseMealsComplete() {
        let entries = [
            makeFoodEntrySummary(.breakfast),
            makeFoodEntrySummary(.lunch),
            makeFoodEntrySummary(.dinner)
        ]

        XCTAssertEqual(
            HomeMealSummaryFormatter.headerActionTitle(foodEntries: entries),
            "今日已记录"
        )
        XCTAssertFalse(HomeMealSummaryFormatter.hasRecordAction(foodEntries: entries))
        XCTAssertNil(HomeMealSummaryFormatter.singleMissingMealType(foodEntries: entries))
    }

    private func makeFoodEntrySummary(_ mealType: MealType) -> FoodEntrySummary {
        FoodEntrySummary(
            id: UUID(),
            mealType: mealType,
            totalCaloriesKcal: 235,
            itemNames: ["鸡蛋", "豆浆"]
        )
    }
}
