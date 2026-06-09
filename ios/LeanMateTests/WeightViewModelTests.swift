import XCTest
@testable import LeanMate

@MainActor
final class WeightViewModelTests: XCTestCase {
    func testWeightRangeValidationDoesNotCallAPI() async {
        let apiClient = WeightAPIClientStub()
        let viewModel = WeightViewModel(
            apiClient: apiClient,
            recordDate: MockData.today,
            weightText: "19.9"
        )

        let succeeded = await viewModel.save()
        let saveCallCount = await apiClient.saveWeightCallCount

        XCTAssertFalse(succeeded)
        XCTAssertEqual(saveCallCount, 0)
        XCTAssertEqual(viewModel.state, .localValidationFailed("体重需在 20-300 kg 之间"))
    }

    func testWeightSaveSuccess() async {
        let apiClient = WeightAPIClientStub()
        let viewModel = WeightViewModel(
            apiClient: apiClient,
            recordDate: MockData.today,
            weightText: "55.8",
            noteText: "晨起空腹"
        )

        let succeeded = await viewModel.save()
        let request = await apiClient.lastWeightRequest

        XCTAssertTrue(succeeded)
        XCTAssertEqual(viewModel.state, .saved)
        XCTAssertEqual(request?.weightKg, 55.8)
        XCTAssertEqual(request?.note, "晨起空腹")
    }

    func testVisitorWeightSavePersistsLocally() async throws {
        let apiClient = WeightAPIClientStub()
        let localStore = InMemoryLocalStore()
        let viewModel = WeightViewModel(
            apiClient: apiClient,
            localStore: localStore,
            savesLocally: true,
            recordDate: MockData.today,
            weightText: "56.2",
            noteText: "本地"
        )

        let succeeded = await viewModel.save()
        let saveCallCount = await apiClient.saveWeightCallCount
        let entries = try await localStore.localWeightEntries()

        XCTAssertTrue(succeeded)
        XCTAssertEqual(saveCallCount, 0)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].weightKg, 56.2)
        XCTAssertEqual(entries[0].note, "本地")
    }

    func testWeightSaveFailureKeepsInput() async {
        let apiClient = WeightAPIClientStub(saveWeightResult: .failure(.networkUnavailable))
        let viewModel = WeightViewModel(
            apiClient: apiClient,
            recordDate: MockData.today,
            weightText: "56.2",
            noteText: "晚饭后"
        )

        let succeeded = await viewModel.save()

        XCTAssertFalse(succeeded)
        XCTAssertEqual(viewModel.weightText, "56.2")
        XCTAssertEqual(viewModel.noteText, "晚饭后")
        if case .saveFailed(let message) = viewModel.state {
            XCTAssertEqual(message, "网络不可用，请稍后重试")
        } else {
            XCTFail("Expected saveFailed state")
        }
    }

    func testRepeatedWeightSaveOnlyCallsAPIOnce() async {
        let apiClient = WeightAPIClientStub(delayNanoseconds: 50_000_000)
        let viewModel = WeightViewModel(
            apiClient: apiClient,
            recordDate: MockData.today,
            weightText: "55.8"
        )

        let first = Task { await viewModel.save() }
        let second = Task { await viewModel.save() }
        _ = await (first.value, second.value)
        let saveCallCount = await apiClient.saveWeightCallCount

        XCTAssertEqual(saveCallCount, 1)
    }
}

private actor WeightAPIClientStub: APIClient {
    private let saveWeightResult: Result<WeightEntrySaveResult, AppError>
    private let delayNanoseconds: UInt64

    private(set) var saveWeightCallCount = 0
    private(set) var lastWeightRequest: SaveWeightEntryRequest?

    init(
        saveWeightResult: Result<WeightEntrySaveResult, AppError> = .success(
            WeightEntrySaveResult(
                entry: WeightEntry(
                    recordDate: MockData.today,
                    weightKg: 55.8,
                    note: nil,
                    id: UUID(),
                    createdAt: MockData.today
                ),
                today: MockData.nutritionSnapshot
            )
        ),
        delayNanoseconds: UInt64 = 0
    ) {
        self.saveWeightResult = saveWeightResult
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
        saveWeightCallCount += 1
        lastWeightRequest = request
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        switch saveWeightResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
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
