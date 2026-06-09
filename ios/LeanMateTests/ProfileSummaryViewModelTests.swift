import XCTest
@testable import LeanMate

@MainActor
final class ProfileSummaryViewModelTests: XCTestCase {
    func testSuccessLoadsProfileAndStreakFromAPI() async {
        let viewModel = ProfileSummaryViewModel(apiClient: MockAPIClient(delayNanoseconds: 0))

        await viewModel.load()

        if case .loaded(let snapshot) = viewModel.state {
            XCTAssertEqual(snapshot.profile.dailyCalorieTargetKcal, 1800)
            XCTAssertEqual(snapshot.streak.currentDays, 12)
            XCTAssertEqual(snapshot.streak.longestDays, 18)
            XCTAssertEqual(viewModel.milestoneToPresent?.days, 7)
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func testEmptyStreakDoesNotPresentMilestone() async {
        let viewModel = ProfileSummaryViewModel(
            apiClient: MockAPIClient(scenario: .empty, delayNanoseconds: 0)
        )

        await viewModel.load()

        if case .loaded(let snapshot) = viewModel.state {
            XCTAssertEqual(snapshot.streak.currentDays, 0)
            XCTAssertEqual(snapshot.streak.longestDays, 0)
            XCTAssertNil(viewModel.milestoneToPresent)
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func testProfileIncompleteScenarioRoutesToProfileIncompleteState() async {
        let viewModel = ProfileSummaryViewModel(
            apiClient: MockAPIClient(scenario: .profileIncomplete, delayNanoseconds: 0)
        )

        await viewModel.load()

        if case .profileIncomplete = viewModel.state {
            XCTAssertNil(viewModel.milestoneToPresent)
        } else {
            XCTFail("Expected profileIncomplete state")
        }
    }

    func testVisitorStateDoesNotCallAPI() async {
        let viewModel = ProfileSummaryViewModel.visitor(localStore: InMemoryLocalStore())

        await viewModel.load()

        if case .profileIncomplete = viewModel.state {
            XCTAssertNil(viewModel.milestoneToPresent)
        } else {
            XCTFail("Expected profileIncomplete state")
        }
    }

    func testVisitorLoadsLocalProfileWhenAvailable() async throws {
        let localStore = InMemoryLocalStore()
        try await localStore.saveLocalProfile(MockData.profile)
        let viewModel = ProfileSummaryViewModel.visitor(localStore: localStore)

        await viewModel.load()

        if case .loaded(let snapshot) = viewModel.state {
            XCTAssertEqual(snapshot.profile.currentWeightKg, 55.8)
            XCTAssertEqual(snapshot.displayName, "我的档案")
        } else {
            XCTFail("Expected loaded state")
        }
    }

    func testUnauthorizedClearsTokensAndRequiresLogin() async throws {
        let tokenStore = InMemoryTokenStore()
        try await tokenStore.saveTokens(AuthTokens(accessToken: "expired", refreshToken: "refresh"))
        let apiClient = ProfileSummaryAPIClientStub(currentUserResult: .failure(.unauthorized))
        let viewModel = ProfileSummaryViewModel(apiClient: apiClient, tokenStore: tokenStore)

        await viewModel.load()
        let tokens = try await tokenStore.loadTokens()

        XCTAssertNil(tokens)
        if case .error(_, let recovery) = viewModel.state {
            XCTAssertEqual(recovery, .login)
        } else {
            XCTFail("Expected login recovery")
        }
    }

    func testRepeatedRefreshOnlyCallsAPIOnce() async {
        let apiClient = ProfileSummaryAPIClientStub(delayNanoseconds: 50_000_000)
        let viewModel = ProfileSummaryViewModel(apiClient: apiClient)

        let first = Task { await viewModel.refresh() }
        let second = Task { await viewModel.refresh() }
        _ = await (first.value, second.value)
        let currentUserCallCount = await apiClient.currentUserCallCount
        let profileCallCount = await apiClient.profileCallCount
        let streakCallCount = await apiClient.streakCallCount

        XCTAssertEqual(currentUserCallCount, 1)
        XCTAssertEqual(profileCallCount, 1)
        XCTAssertEqual(streakCallCount, 1)
    }

    func testDismissedHighestMilestoneDoesNotPresentLowerMilestoneOnRefresh() async {
        let apiClient = ProfileSummaryAPIClientStub()
        let viewModel = ProfileSummaryViewModel(apiClient: apiClient)

        await viewModel.load()
        XCTAssertEqual(viewModel.milestoneToPresent?.days, 7)

        viewModel.dismissMilestone()
        await viewModel.refresh()

        XCTAssertNil(viewModel.milestoneToPresent)
    }
}

private actor ProfileSummaryAPIClientStub: APIClient {
    private let currentUserResult: Result<CurrentUser, AppError>
    private let profileResult: Result<ProfilePayload, AppError>
    private let streakResult: Result<Streak, AppError>
    private let delayNanoseconds: UInt64

    private(set) var currentUserCallCount = 0
    private(set) var profileCallCount = 0
    private(set) var streakCallCount = 0

    init(
        currentUserResult: Result<CurrentUser, AppError> = .success(MockData.currentUser),
        profileResult: Result<ProfilePayload, AppError> = .success(
            ProfilePayload(profileCompleted: true, profile: MockData.profile)
        ),
        streakResult: Result<Streak, AppError> = .success(MockData.streak),
        delayNanoseconds: UInt64 = 0
    ) {
        self.currentUserResult = currentUserResult
        self.profileResult = profileResult
        self.streakResult = streakResult
        self.delayNanoseconds = delayNanoseconds
    }

    func oauthLogin(_ request: OAuthLoginRequest) async throws -> AuthToken {
        throw AppError.unknown
    }

    func refreshToken(_ request: RefreshTokenRequest) async throws -> AuthToken {
        throw AppError.unknown
    }

    func logout(_ request: LogoutRequest?) async throws {}

    func currentUser() async throws -> CurrentUser {
        currentUserCallCount += 1
        try await waitIfNeeded()
        switch currentUserResult {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }

    func profile() async throws -> ProfilePayload {
        profileCallCount += 1
        try await waitIfNeeded()
        switch profileResult {
        case .success(let profile):
            return profile
        case .failure(let error):
            throw error
        }
    }

    func saveProfile(_ request: SaveUserProfileRequest) async throws -> ProfilePayload {
        throw AppError.unknown
    }

    func todayHome(date: Date?) async throws -> TodayHome {
        throw AppError.unknown
    }

    func createPhotoRecognition(
        imageData: Data,
        fileName: String,
        mimeType: String,
        mealType: MealType,
        mealDate: Date?,
        note: String?
    ) async throws -> RecognitionTask {
        throw AppError.unknown
    }

    func createTextRecognition(_ request: TextRecognitionRequest) async throws -> RecognitionTask {
        throw AppError.unknown
    }

    func recognitionTask(id: UUID) async throws -> RecognitionTask {
        throw AppError.unknown
    }

    func dietEntries(date: Date) async throws -> [FoodEntry] {
        throw AppError.unknown
    }

    func saveDietEntry(_ request: SaveFoodEntryRequest) async throws -> FoodEntrySaveResult {
        throw AppError.unknown
    }

    func updateDietEntry(id: UUID, _ request: SaveFoodEntryRequest) async throws -> FoodEntrySaveResult {
        throw AppError.unknown
    }

    func deleteDietEntry(id: UUID) async throws {}

    func weightEntries(startDate: Date, endDate: Date) async throws -> [WeightEntry] {
        throw AppError.unknown
    }

    func saveWeight(_ request: SaveWeightEntryRequest) async throws -> WeightEntrySaveResult {
        throw AppError.unknown
    }

    func dailyReport(date: Date) async throws -> DailyReport? {
        throw AppError.unknown
    }

    func generateDailyReport(_ request: GenerateDailyReportRequest?) async throws -> DailyReport? {
        throw AppError.unknown
    }

    func markDailyReportViewed(reportId: UUID) async throws -> DailyReport? {
        throw AppError.unknown
    }

    func streak() async throws -> Streak {
        streakCallCount += 1
        try await waitIfNeeded()
        switch streakResult {
        case .success(let streak):
            return streak
        case .failure(let error):
            throw error
        }
    }

    private func waitIfNeeded() async throws {
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
    }
}
