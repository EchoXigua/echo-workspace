import Foundation

final class MockAPIClient: APIClient, @unchecked Sendable {
    enum Scenario: Sendable {
        case success
        case empty
        case error(AppError)
        case profileIncomplete
        case recognitionRunning
        case recognitionFailed
    }

    private let scenario: Scenario
    private let delayNanoseconds: UInt64
    private var completedProfile: UserProfile?

    init(scenario: Scenario = .success, delayNanoseconds: UInt64 = 150_000_000) {
        self.scenario = scenario
        self.delayNanoseconds = delayNanoseconds
    }

    func oauthLogin(_ request: OAuthLoginRequest) async throws -> AuthToken {
        try await prepare()
        let profileCompleted = isProfileCompleted
        return AuthToken(
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token",
            tokenType: "Bearer",
            expiresIn: 3600,
            user: currentUserPayload,
            profileCompleted: profileCompleted
        )
    }

    func refreshToken(_ request: RefreshTokenRequest) async throws -> AuthToken {
        try await oauthLogin(
            OAuthLoginRequest(provider: .apple, identityToken: "mock", authorizationCode: nil, deviceId: nil)
        )
    }

    func logout(_ request: LogoutRequest?) async throws {
        try await prepare()
    }

    func currentUser() async throws -> CurrentUser {
        try await prepare()
        return currentUserPayload
    }

    func profile() async throws -> ProfilePayload {
        try await prepare()
        if case .profileIncomplete = scenario, completedProfile == nil {
            return ProfilePayload(profileCompleted: false, profile: nil)
        }
        return ProfilePayload(profileCompleted: true, profile: completedProfile ?? MockData.profile)
    }

    func saveProfile(_ request: SaveUserProfileRequest) async throws -> ProfilePayload {
        try await prepare()
        let profile = UserProfile(
            gender: request.gender,
            age: request.age,
            heightCm: request.heightCm,
            currentWeightKg: request.currentWeightKg,
            targetWeightKg: request.targetWeightKg,
            activityLevel: request.activityLevel,
            timezone: request.timezone,
            targetDate: request.targetDate,
            bmi: 19.8,
            bmrKcal: 1320,
            dailyCalorieTargetKcal: 1800
        )
        completedProfile = profile
        return ProfilePayload(profileCompleted: true, profile: profile)
    }

    func todayHome(date: Date?) async throws -> TodayHome {
        try await prepare()
        if case .profileIncomplete = scenario, completedProfile == nil {
            return TodayHome(
                date: date ?? MockData.today,
                profileCompleted: false,
                calorieTargetKcal: 0,
                caloriesInKcal: 0,
                remainingCaloriesKcal: 0,
                proteinG: nil,
                fatG: nil,
                carbsG: nil,
                currentWeightKg: nil,
                streakDays: 0,
                reportSummary: nil,
                foodEntries: []
            )
        }
        if case .empty = scenario {
            return TodayHome(
                date: date ?? MockData.today,
                profileCompleted: true,
                calorieTargetKcal: 1800,
                caloriesInKcal: 0,
                remainingCaloriesKcal: 1800,
                proteinG: 0,
                fatG: 0,
                carbsG: 0,
                currentWeightKg: nil,
                streakDays: 0,
                reportSummary: nil,
                foodEntries: []
            )
        }
        return MockData.todayHome
    }

    func createPhotoRecognition(
        imageData: Data,
        fileName: String,
        mimeType: String,
        mealType: MealType,
        mealDate: Date?,
        note: String?
    ) async throws -> RecognitionTask {
        try await recognitionTask(id: MockData.taskId)
    }

    func createTextRecognition(_ request: TextRecognitionRequest) async throws -> RecognitionTask {
        try await recognitionTask(id: MockData.taskId)
    }

    func recognitionTask(id: UUID) async throws -> RecognitionTask {
        try await prepare()

        let status: RecognitionStatus
        let draft: FoodEntryDraft?
        let errorCode: String?
        let errorMessage: String?

        switch scenario {
        case .recognitionRunning:
            status = .running
            draft = nil
            errorCode = nil
            errorMessage = nil
        case .recognitionFailed:
            status = .failed
            draft = nil
            errorCode = "AI_RECOGNITION_FAILED"
            errorMessage = "识别失败"
        default:
            status = .succeeded
            draft = FoodEntryDraft(
                mealDate: MockData.today,
                mealType: .breakfast,
                sourceType: .text,
                items: MockData.foodItems
            )
            errorCode = nil
            errorMessage = nil
        }

        return RecognitionTask(
            id: id,
            sourceType: .text,
            mealDate: MockData.today,
            mealType: .breakfast,
            status: status,
            draftEntry: draft,
            errorCode: errorCode,
            errorMessage: errorMessage,
            createdAt: MockData.today,
            finishedAt: status == .succeeded ? MockData.today : nil
        )
    }

    func dietEntries(date: Date) async throws -> [FoodEntry] {
        try await prepare()
        if case .empty = scenario {
            return []
        }
        return [MockData.foodEntry]
    }

    func saveDietEntry(_ request: SaveFoodEntryRequest) async throws -> FoodEntrySaveResult {
        try await prepare()
        return FoodEntrySaveResult(entry: makeFoodEntry(from: request), today: MockData.nutritionSnapshot)
    }

    func updateDietEntry(id: UUID, _ request: SaveFoodEntryRequest) async throws -> FoodEntrySaveResult {
        try await prepare()
        return FoodEntrySaveResult(entry: makeFoodEntry(from: request, id: id), today: MockData.nutritionSnapshot)
    }

    func deleteDietEntry(id: UUID) async throws {
        try await prepare()
    }

    func weightEntries(startDate: Date, endDate: Date) async throws -> [WeightEntry] {
        try await prepare()
        if case .empty = scenario {
            return []
        }
        return [
            WeightEntry(
                recordDate: MockData.today,
                weightKg: 55.8,
                note: nil,
                id: UUID(),
                createdAt: MockData.today
            )
        ]
    }

    func saveWeight(_ request: SaveWeightEntryRequest) async throws -> WeightEntrySaveResult {
        try await prepare()
        let entry = WeightEntry(
            recordDate: request.recordDate,
            weightKg: request.weightKg,
            note: request.note,
            id: UUID(),
            createdAt: MockData.today
        )
        return WeightEntrySaveResult(entry: entry, today: MockData.nutritionSnapshot)
    }

    func dailyReport(date: Date) async throws -> DailyReport? {
        try await prepare()
        if case .empty = scenario {
            return nil
        }
        return MockData.dailyReport
    }

    func generateDailyReport(_ request: GenerateDailyReportRequest?) async throws -> DailyReport? {
        try await prepare()
        return MockData.dailyReport
    }

    func markDailyReportViewed(reportId: UUID) async throws -> DailyReport? {
        try await prepare()
        let report = MockData.dailyReport
        return DailyReport(
            id: report.id,
            reportDate: report.reportDate,
            score: report.score,
            summary: report.summary,
            problem: report.problem,
            suggestion: report.suggestion,
            status: .viewed,
            generatedAt: report.generatedAt,
            viewedAt: MockData.today
        )
    }

    func streak() async throws -> Streak {
        try await prepare()
        if case .empty = scenario {
            return MockData.emptyStreak
        }
        return MockData.streak
    }
}

private extension MockAPIClient {
    var isProfileCompleted: Bool {
        if completedProfile != nil {
            return true
        }
        if case .profileIncomplete = scenario {
            return false
        }
        return true
    }

    var currentUserPayload: CurrentUser {
        guard isProfileCompleted else {
            return MockData.profileIncompleteUser
        }
        return MockData.currentUser
    }

    func prepare() async throws {
        try await Task.sleep(nanoseconds: delayNanoseconds)
        if case .error(let error) = scenario {
            throw error
        }
    }

    func makeFoodEntry(from request: SaveFoodEntryRequest, id: UUID = UUID()) -> FoodEntry {
        let items = request.items.map { item in
            FoodItem(
                id: item.id ?? UUID(),
                name: item.name,
                quantityText: item.quantityText,
                weightG: item.weightG,
                caloriesKcal: item.caloriesKcal,
                proteinG: item.proteinG,
                fatG: item.fatG,
                carbsG: item.carbsG,
                confidence: item.confidence,
                userEdited: item.userEdited ?? false
            )
        }

        return FoodEntry(
            id: id,
            recognitionTaskId: request.recognitionTaskId,
            mealDate: request.mealDate,
            mealType: request.mealType,
            sourceType: request.sourceType,
            rawText: request.rawText,
            imageUrl: request.imageUrl,
            status: .confirmed,
            totalCaloriesKcal: items.compactMap(\.caloriesKcal).reduce(0, +),
            totalProteinG: items.compactMap(\.proteinG).reduce(0, +),
            totalFatG: items.compactMap(\.fatG).reduce(0, +),
            totalCarbsG: items.compactMap(\.carbsG).reduce(0, +),
            items: items,
            createdAt: MockData.today
        )
    }
}
