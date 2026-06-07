import XCTest
@testable import LeanMate

@MainActor
final class DietEntryViewModelTests: XCTestCase {
    func testManualValidationFailureDoesNotCallAPI() async {
        let apiClient = DietAPIClientStub()
        let viewModel = DietEntryViewModel(apiClient: apiClient, mealDate: MockData.today)
        viewModel.manualItem.name = ""

        let succeeded = await viewModel.saveManualEntry()
        let saveCallCount = await apiClient.saveDietEntryCallCount

        XCTAssertFalse(succeeded)
        XCTAssertEqual(saveCallCount, 0)
        XCTAssertEqual(viewModel.validationMessage, "食物名称不能为空")
    }

    func testManualSaveSuccessUsesManualSource() async {
        let apiClient = DietAPIClientStub()
        let viewModel = DietEntryViewModel(apiClient: apiClient, mealDate: MockData.today)
        viewModel.manualItem.name = "鸡蛋"
        viewModel.manualItem.quantityText = "2 个"
        viewModel.manualItem.caloriesText = "140"

        let succeeded = await viewModel.saveManualEntry()
        let request = await apiClient.lastDietRequest

        XCTAssertTrue(succeeded)
        XCTAssertEqual(viewModel.state, .saveSucceeded)
        XCTAssertEqual(request?.sourceType, .manual)
        XCTAssertEqual(request?.items.first?.name, "鸡蛋")
    }

    func testManualSaveFailureKeepsInput() async {
        let apiClient = DietAPIClientStub(saveDietResult: .failure(.networkUnavailable))
        let viewModel = DietEntryViewModel(apiClient: apiClient, mealDate: MockData.today)
        viewModel.manualItem.name = "豆浆"

        let succeeded = await viewModel.saveManualEntry()

        XCTAssertFalse(succeeded)
        XCTAssertEqual(viewModel.manualItem.name, "豆浆")
        if case .saveFailed(let message) = viewModel.state {
            XCTAssertEqual(message, "网络不可用，请稍后重试")
        } else {
            XCTFail("Expected saveFailed state")
        }
    }

    func testTextRecognitionSuccessEntersConfirmation() async {
        let apiClient = DietAPIClientStub()
        let viewModel = DietEntryViewModel(apiClient: apiClient, mealDate: MockData.today)
        viewModel.textInput = "早餐两个鸡蛋一杯豆浆"

        await viewModel.startTextRecognition()
        let createCallCount = await apiClient.createTextRecognitionCallCount
        let taskCallCount = await apiClient.recognitionTaskCallCount

        XCTAssertEqual(createCallCount, 1)
        XCTAssertEqual(taskCallCount, 1)
        XCTAssertEqual(viewModel.mode, .confirmation)
        XCTAssertEqual(viewModel.state, .confirmation)
        XCTAssertEqual(viewModel.confirmationItems.count, 2)
    }

    func testTextRecognitionFailureCanSwitchToManual() async {
        let apiClient = DietAPIClientStub(
            recognitionTaskResult: .success(DietAPIClientStub.failedRecognitionTask)
        )
        let viewModel = DietEntryViewModel(apiClient: apiClient, mealDate: MockData.today)
        viewModel.textInput = "今天吃了一份不确定的便当"

        await viewModel.startTextRecognition()
        viewModel.switchFailedRecognitionToManual()

        XCTAssertEqual(viewModel.mode, .manual)
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.manualItem.name, "今天吃了一份不确定的便当")
    }

    func testRepeatedManualSaveOnlyCallsAPIOnce() async {
        let apiClient = DietAPIClientStub(delayNanoseconds: 50_000_000)
        let viewModel = DietEntryViewModel(apiClient: apiClient, mealDate: MockData.today)
        viewModel.manualItem.name = "鸡蛋"

        let first = Task { await viewModel.saveManualEntry() }
        let second = Task { await viewModel.saveManualEntry() }
        _ = await (first.value, second.value)
        let saveCallCount = await apiClient.saveDietEntryCallCount

        XCTAssertEqual(saveCallCount, 1)
    }
}

private actor DietAPIClientStub: APIClient {
    static let succeededRecognitionTask = RecognitionTask(
        id: MockData.taskId,
        sourceType: .text,
        mealDate: MockData.today,
        mealType: .breakfast,
        status: .succeeded,
        draftEntry: FoodEntryDraft(
            mealDate: MockData.today,
            mealType: .breakfast,
            sourceType: .text,
            items: MockData.foodItems
        ),
        errorCode: nil,
        errorMessage: nil,
        createdAt: MockData.today,
        finishedAt: MockData.today
    )

    static let failedRecognitionTask = RecognitionTask(
        id: MockData.taskId,
        sourceType: .text,
        mealDate: MockData.today,
        mealType: .breakfast,
        status: .failed,
        draftEntry: nil,
        errorCode: "AI_RECOGNITION_FAILED",
        errorMessage: "识别失败",
        createdAt: MockData.today,
        finishedAt: MockData.today
    )

    private let recognitionTaskResult: Result<RecognitionTask, AppError>
    private let saveDietResult: Result<FoodEntrySaveResult, AppError>
    private let delayNanoseconds: UInt64

    private(set) var createTextRecognitionCallCount = 0
    private(set) var recognitionTaskCallCount = 0
    private(set) var saveDietEntryCallCount = 0
    private(set) var lastDietRequest: SaveFoodEntryRequest?

    init(
        recognitionTaskResult: Result<RecognitionTask, AppError> = .success(succeededRecognitionTask),
        saveDietResult: Result<FoodEntrySaveResult, AppError> = .success(
            FoodEntrySaveResult(entry: MockData.foodEntry, today: MockData.nutritionSnapshot)
        ),
        delayNanoseconds: UInt64 = 0
    ) {
        self.recognitionTaskResult = recognitionTaskResult
        self.saveDietResult = saveDietResult
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
        createTextRecognitionCallCount += 1
        return Self.succeededRecognitionTask
    }

    func recognitionTask(id: UUID) async throws -> RecognitionTask {
        recognitionTaskCallCount += 1
        switch recognitionTaskResult {
        case .success(let task):
            return task
        case .failure(let error):
            throw error
        }
    }

    func dietEntries(date: Date) async throws -> [FoodEntry] {
        throw AppError.unknown
    }

    func saveDietEntry(_ request: SaveFoodEntryRequest) async throws -> FoodEntrySaveResult {
        saveDietEntryCallCount += 1
        lastDietRequest = request
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        switch saveDietResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
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
