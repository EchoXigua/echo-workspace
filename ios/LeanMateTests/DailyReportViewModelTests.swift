import XCTest
@testable import LeanMate

@MainActor
final class DailyReportViewModelTests: XCTestCase {
    func testLoadExistingReportEntersGeneratedState() async {
        let apiClient = ReportAPIClientStub()
        let viewModel = DailyReportViewModel(apiClient: apiClient, reportDate: MockData.today)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .generated)
        XCTAssertEqual(viewModel.report?.id, MockData.reportId)
    }

    func testLoadEmptyReportEntersEmptyState() async {
        let apiClient = ReportAPIClientStub(loadResult: .success(nil))
        let viewModel = DailyReportViewModel(apiClient: apiClient, reportDate: MockData.today)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .empty)
        XCTAssertNil(viewModel.report)
    }

    func testGenerateReportSuccess() async {
        let apiClient = ReportAPIClientStub(loadResult: .success(nil))
        let viewModel = DailyReportViewModel(apiClient: apiClient, reportDate: MockData.today)

        await viewModel.generate()
        let generateCallCount = await apiClient.generateCallCount

        XCTAssertEqual(generateCallCount, 1)
        XCTAssertEqual(viewModel.state, .generated)
        XCTAssertEqual(viewModel.scoreText, "84")
    }

    func testGenerateReportFailure() async {
        let apiClient = ReportAPIClientStub(generateResult: .failure(.aiServiceUnavailable))
        let viewModel = DailyReportViewModel(apiClient: apiClient, reportDate: MockData.today)

        await viewModel.generate()

        if case .failed(let message) = viewModel.state {
            XCTAssertEqual(message, "AI 服务暂时不可用")
        } else {
            XCTFail("Expected failed state")
        }
    }

    func testMarkViewedWhenGenerated() async {
        let apiClient = ReportAPIClientStub()
        let viewModel = DailyReportViewModel(apiClient: apiClient, reportDate: MockData.today)

        await viewModel.load()
        await viewModel.markViewedIfNeeded()
        let markViewedCallCount = await apiClient.markViewedCallCount

        XCTAssertEqual(markViewedCallCount, 1)
        XCTAssertEqual(viewModel.state, .viewed)
        XCTAssertEqual(viewModel.report?.status, .viewed)
    }

    func testRepeatedGenerateOnlyCallsAPIOnce() async {
        let apiClient = ReportAPIClientStub(delayNanoseconds: 50_000_000)
        let viewModel = DailyReportViewModel(apiClient: apiClient, reportDate: MockData.today)

        let first = Task { await viewModel.generate() }
        let second = Task { await viewModel.generate() }
        _ = await (first.value, second.value)
        let generateCallCount = await apiClient.generateCallCount

        XCTAssertEqual(generateCallCount, 1)
    }
}

private actor ReportAPIClientStub: APIClient {
    private let loadResult: Result<DailyReport?, AppError>
    private let generateResult: Result<DailyReport?, AppError>
    private let markViewedResult: Result<DailyReport?, AppError>
    private let delayNanoseconds: UInt64

    private(set) var generateCallCount = 0
    private(set) var markViewedCallCount = 0

    init(
        loadResult: Result<DailyReport?, AppError> = .success(MockData.dailyReport),
        generateResult: Result<DailyReport?, AppError> = .success(MockData.dailyReport),
        markViewedResult: Result<DailyReport?, AppError> = .success(ReportAPIClientStub.viewedReport),
        delayNanoseconds: UInt64 = 0
    ) {
        self.loadResult = loadResult
        self.generateResult = generateResult
        self.markViewedResult = markViewedResult
        self.delayNanoseconds = delayNanoseconds
    }

    static let viewedReport = DailyReport(
        id: MockData.reportId,
        reportDate: MockData.today,
        score: MockData.dailyReport.score,
        summary: MockData.dailyReport.summary,
        problem: MockData.dailyReport.problem,
        suggestion: MockData.dailyReport.suggestion,
        status: .viewed,
        generatedAt: MockData.dailyReport.generatedAt,
        viewedAt: MockData.today
    )

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
        throw AppError.unknown
    }

    func dailyReport(date: Date) async throws -> DailyReport? {
        switch loadResult {
        case .success(let report):
            return report
        case .failure(let error):
            throw error
        }
    }

    func generateDailyReport(_ request: GenerateDailyReportRequest?) async throws -> DailyReport? {
        generateCallCount += 1
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        switch generateResult {
        case .success(let report):
            return report
        case .failure(let error):
            throw error
        }
    }

    func markDailyReportViewed(reportId: UUID) async throws -> DailyReport? {
        markViewedCallCount += 1
        switch markViewedResult {
        case .success(let report):
            return report
        case .failure(let error):
            throw error
        }
    }

    func streak() async throws -> Streak {
        throw AppError.unknown
    }
}
