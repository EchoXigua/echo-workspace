import XCTest
@testable import LeanMate

@MainActor
final class FirstBatchViewModelTests: XCTestCase {
    func testAppleSignInRequiresAgreementBeforeAuthorization() async throws {
        let authorizer = AppleSignInAuthorizerSpy()
        let viewModel = OnboardingViewModel(
            apiClient: MockAPIClient(delayNanoseconds: 0),
            tokenStore: InMemoryTokenStore(),
            localStore: InMemoryLocalStore(),
            appleSignInAuthorizer: authorizer
        )

        let destination = await viewModel.signInWithApple()

        XCTAssertNil(destination)
        XCTAssertEqual(authorizer.signInCallCount, 0)
        XCTAssertEqual(viewModel.agreementMessage, "请先阅读并同意用户协议和隐私政策")
    }

    func testAppleSignInRoutesToHomeWhenProfileIsCompleted() async throws {
        let authorizer = AppleSignInAuthorizerSpy()
        let viewModel = OnboardingViewModel(
            apiClient: MockAPIClient(delayNanoseconds: 0),
            tokenStore: InMemoryTokenStore(),
            localStore: InMemoryLocalStore(),
            appleSignInAuthorizer: authorizer
        )

        viewModel.toggleAgreement()
        let destination = await viewModel.signInWithApple()

        XCTAssertEqual(destination, .home)
        XCTAssertEqual(authorizer.signInCallCount, 1)
    }

    func testAppleSignInCancellationKeepsAgreementAndShowsRetryState() async throws {
        let authorizer = AppleSignInAuthorizerSpy(result: .failure(AppleSignInError.cancelled))
        let viewModel = OnboardingViewModel(
            apiClient: MockAPIClient(delayNanoseconds: 0),
            tokenStore: InMemoryTokenStore(),
            localStore: InMemoryLocalStore(),
            appleSignInAuthorizer: authorizer
        )

        viewModel.toggleAgreement()
        let destination = await viewModel.signInWithApple()

        XCTAssertNil(destination)
        XCTAssertTrue(viewModel.hasAcceptedAgreement)
        if case .loginFailed(let message) = viewModel.state {
            XCTAssertEqual(message, "Apple 登录未完成，请重试或先随便看看。")
        } else {
            XCTFail("Expected loginFailed state")
        }
    }

    func testStartGuestSessionPersistsLocalGuestState() async throws {
        let tokenStore = InMemoryTokenStore()
        let localStore = InMemoryLocalStore()
        let viewModel = OnboardingViewModel(
            apiClient: MockAPIClient(scenario: .profileIncomplete, delayNanoseconds: 0),
            tokenStore: tokenStore,
            localStore: localStore
        )

        let destination = await viewModel.startGuestSession()
        let tokens = try await tokenStore.loadTokens()
        let session = try await localStore.guestSession()

        XCTAssertEqual(destination, .visitorHome)
        XCTAssertNil(tokens)
        XCTAssertNotNil(session)
    }

    func testMockLoginSyncRoutesToHomeWhenProfileIsCompleted() async throws {
        let tokenStore = InMemoryTokenStore()
        let localStore = InMemoryLocalStore()
        let viewModel = OnboardingViewModel(
            apiClient: MockAPIClient(delayNanoseconds: 0),
            tokenStore: tokenStore,
            localStore: localStore
        )

        let destination = await viewModel.mockLoginAndSyncGuestData()

        XCTAssertEqual(destination, .home)
    }

    func testMockLoginSyncRoutesToProfileSetupWhenProfileIsIncomplete() async throws {
        let tokenStore = InMemoryTokenStore()
        let localStore = InMemoryLocalStore()
        let viewModel = OnboardingViewModel(
            apiClient: MockAPIClient(scenario: .profileIncomplete, delayNanoseconds: 0),
            tokenStore: tokenStore,
            localStore: localStore
        )

        let destination = await viewModel.mockLoginAndSyncGuestData()

        XCTAssertEqual(destination, .profileSetup)
    }

    func testMockLoginUsesFixedLocalAppleIdentityToken() async throws {
        let apiClient = LoginAPIClientSpy(profileCompleted: true)
        let tokenStore = InMemoryTokenStore()
        let viewModel = OnboardingViewModel(
            apiClient: apiClient,
            tokenStore: tokenStore,
            localStore: InMemoryLocalStore()
        )

        let destination = await viewModel.mockLoginAndSyncGuestData()
        let requests = await apiClient.oauthLoginRequests
        let tokens = try await tokenStore.loadTokens()

        XCTAssertEqual(destination, .home)
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.provider, .apple)
        XCTAssertEqual(requests.first?.identityToken, MockAppleSignInAuthorizer.defaultIdentityToken)
        XCTAssertNil(requests.first?.authorizationCode)
        XCTAssertEqual(tokens?.accessToken, "debug-access-token")
        XCTAssertEqual(tokens?.refreshToken, "debug-refresh-token")
    }

    func testProfileValidationFailureDoesNotCallSaveAPI() async throws {
        let apiClient = ProfileAPIClientStub()
        let viewModel = ProfileSetupViewModel(apiClient: apiClient, timezoneIdentifier: "Asia/Shanghai")
        fillValidProfile(on: viewModel)
        viewModel.ageText = "0"

        let succeeded = await viewModel.save()
        let saveCallCount = await apiClient.saveProfileCallCount

        XCTAssertFalse(succeeded)
        XCTAssertEqual(saveCallCount, 0)
        XCTAssertEqual(viewModel.fieldErrors[.age], "年龄需在 1-120 岁之间")
        XCTAssertEqual(viewModel.state, .localValidationFailed)
    }

    func testProfileLowTargetWeightWithinRangeCanCallSaveAPI() async throws {
        let apiClient = ProfileAPIClientStub()
        let viewModel = ProfileSetupViewModel(apiClient: apiClient, timezoneIdentifier: "Asia/Shanghai")
        fillValidProfile(on: viewModel)
        viewModel.targetWeightText = "52"

        let succeeded = await viewModel.save()
        let saveCallCount = await apiClient.saveProfileCallCount

        XCTAssertTrue(succeeded)
        XCTAssertEqual(saveCallCount, 1)
    }

    func testProfileSafeTargetWeightCanCallSaveAPI() async throws {
        let apiClient = ProfileAPIClientStub()
        let viewModel = ProfileSetupViewModel(apiClient: apiClient, timezoneIdentifier: "Asia/Shanghai")
        fillValidProfile(on: viewModel)

        let succeeded = await viewModel.save()
        let saveCallCount = await apiClient.saveProfileCallCount

        XCTAssertTrue(succeeded)
        XCTAssertEqual(saveCallCount, 1)
    }

    func testProfileSaveSuccessStoresReturnedGoalResult() async throws {
        let apiClient = ProfileAPIClientStub()
        let viewModel = ProfileSetupViewModel(apiClient: apiClient, timezoneIdentifier: "Asia/Shanghai")
        fillValidProfile(on: viewModel)

        let succeeded = await viewModel.save()
        let saveCallCount = await apiClient.saveProfileCallCount

        XCTAssertTrue(succeeded)
        XCTAssertEqual(saveCallCount, 1)
        XCTAssertEqual(viewModel.state, .saveSucceeded)
        XCTAssertEqual(viewModel.savedProfile?.bmi, 19.8)
        XCTAssertEqual(viewModel.savedProfile?.bmrKcal, 1320)
        XCTAssertEqual(viewModel.savedProfile?.dailyCalorieTargetKcal, 1800)
    }

    func testVisitorProfileSavePersistsLocallyWithoutCallingAPI() async throws {
        let apiClient = ProfileAPIClientStub()
        let localStore = InMemoryLocalStore()
        let viewModel = ProfileSetupViewModel(
            apiClient: apiClient,
            localStore: localStore,
            savesLocally: true,
            timezoneIdentifier: "Asia/Shanghai"
        )
        fillValidProfile(on: viewModel)

        let succeeded = await viewModel.save()
        let saveCallCount = await apiClient.saveProfileCallCount
        let profile = try await localStore.localProfile()
        let session = try await localStore.guestSession()

        XCTAssertTrue(succeeded)
        XCTAssertEqual(saveCallCount, 0)
        XCTAssertEqual(profile?.currentWeightKg, 55.8)
        XCTAssertNotNil(session)
    }

    func testProfileSaveFailureKeepsUserInput() async throws {
        let apiClient = ProfileAPIClientStub(saveResult: .failure(.networkUnavailable))
        let viewModel = ProfileSetupViewModel(apiClient: apiClient, timezoneIdentifier: "Asia/Shanghai")
        fillValidProfile(on: viewModel)
        viewModel.currentWeightText = "60.5"

        let succeeded = await viewModel.save()

        XCTAssertFalse(succeeded)
        XCTAssertEqual(viewModel.currentWeightText, "60.5")
        if case .saveFailed(let message) = viewModel.state {
            XCTAssertEqual(message, "网络不可用，请稍后重试")
        } else {
            XCTFail("Expected saveFailed state")
        }
    }

    func testRepeatedProfileSaveOnlyCallsAPIOnce() async throws {
        let apiClient = ProfileAPIClientStub(delayNanoseconds: 50_000_000)
        let viewModel = ProfileSetupViewModel(apiClient: apiClient, timezoneIdentifier: "Asia/Shanghai")
        fillValidProfile(on: viewModel)

        let first = Task { await viewModel.save() }
        let second = Task { await viewModel.save() }
        _ = await (first.value, second.value)
        let saveCallCount = await apiClient.saveProfileCallCount

        XCTAssertEqual(saveCallCount, 1)
    }
}

private extension FirstBatchViewModelTests {
    func fillValidProfile(on viewModel: ProfileSetupViewModel) {
        viewModel.gender = .unknown
        viewModel.ageText = "30"
        viewModel.heightText = "168"
        viewModel.currentWeightText = "55.8"
        viewModel.targetWeightText = "52"
        viewModel.activityLevel = .light
    }
}

private actor LoginAPIClientSpy: APIClient {
    private let profileCompleted: Bool
    private(set) var oauthLoginRequests: [OAuthLoginRequest] = []

    init(profileCompleted: Bool) {
        self.profileCompleted = profileCompleted
    }

    func oauthLogin(_ request: OAuthLoginRequest) async throws -> AuthToken {
        oauthLoginRequests.append(request)
        return AuthToken(
            accessToken: "debug-access-token",
            refreshToken: "debug-refresh-token",
            tokenType: "Bearer",
            expiresIn: 3600,
            user: CurrentUser(
                id: MockData.userId,
                nickname: nil,
                avatarUrl: nil,
                status: .active,
                profileCompleted: profileCompleted,
                createdAt: MockData.today
            ),
            profileCompleted: profileCompleted
        )
    }

    func refreshToken(_ request: RefreshTokenRequest) async throws -> AuthToken {
        throw AppError.unknown
    }

    func logout(_ request: LogoutRequest?) async throws {}

    func currentUser() async throws -> CurrentUser {
        throw AppError.unknown
    }

    func profile() async throws -> ProfilePayload {
        throw AppError.unknown
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
        throw AppError.unknown
    }
}

private final class AppleSignInAuthorizerSpy: AppleSignInAuthorizing {
    private let result: Result<AppleSignInCredential, Error>
    private(set) var signInCallCount = 0

    init(
        result: Result<AppleSignInCredential, Error> = .success(
            AppleSignInCredential(
                identityToken: "spy-identity-token",
                authorizationCode: "spy-authorization-code"
            )
        )
    ) {
        self.result = result
    }

    @MainActor
    func signIn() async throws -> AppleSignInCredential {
        signInCallCount += 1
        switch result {
        case .success(let credential):
            return credential
        case .failure(let error):
            throw error
        }
    }
}

private actor ProfileAPIClientStub: APIClient {
    private let profilePayload: ProfilePayload
    private let saveResult: Result<ProfilePayload, AppError>
    private let delayNanoseconds: UInt64

    private(set) var saveProfileCallCount = 0

    init(
        profilePayload: ProfilePayload = ProfilePayload(profileCompleted: false, profile: nil),
        saveResult: Result<ProfilePayload, AppError> = .success(
            ProfilePayload(profileCompleted: true, profile: MockData.profile)
        ),
        delayNanoseconds: UInt64 = 0
    ) {
        self.profilePayload = profilePayload
        self.saveResult = saveResult
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
        throw AppError.unknown
    }

    func profile() async throws -> ProfilePayload {
        profilePayload
    }

    func saveProfile(_ request: SaveUserProfileRequest) async throws -> ProfilePayload {
        saveProfileCallCount += 1
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        switch saveResult {
        case .success(let payload):
            return payload
        case .failure(let error):
            throw error
        }
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
        throw AppError.unknown
    }
}
