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

        if case .profileIncomplete = viewModel.state {
            XCTAssertTrue(true)
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
}
