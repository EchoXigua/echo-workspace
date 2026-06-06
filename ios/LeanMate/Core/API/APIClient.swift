import Foundation

protocol APIClient: Sendable {
    func oauthLogin(_ request: OAuthLoginRequest) async throws -> AuthToken
    func refreshToken(_ request: RefreshTokenRequest) async throws -> AuthToken
    func logout(_ request: LogoutRequest?) async throws
    func currentUser() async throws -> CurrentUser
    func profile() async throws -> ProfilePayload
    func saveProfile(_ request: SaveUserProfileRequest) async throws -> ProfilePayload
    func todayHome(date: Date?) async throws -> TodayHome
    func createPhotoRecognition(
        imageData: Data,
        fileName: String,
        mimeType: String,
        mealType: MealType,
        mealDate: Date?,
        note: String?
    ) async throws -> RecognitionTask
    func createTextRecognition(_ request: TextRecognitionRequest) async throws -> RecognitionTask
    func recognitionTask(id: UUID) async throws -> RecognitionTask
    func dietEntries(date: Date) async throws -> [FoodEntry]
    func saveDietEntry(_ request: SaveFoodEntryRequest) async throws -> FoodEntrySaveResult
    func updateDietEntry(id: UUID, _ request: SaveFoodEntryRequest) async throws -> FoodEntrySaveResult
    func deleteDietEntry(id: UUID) async throws
    func weightEntries(startDate: Date, endDate: Date) async throws -> [WeightEntry]
    func saveWeight(_ request: SaveWeightEntryRequest) async throws -> WeightEntrySaveResult
    func dailyReport(date: Date) async throws -> DailyReport?
    func generateDailyReport(_ request: GenerateDailyReportRequest?) async throws -> DailyReport?
    func markDailyReportViewed(reportId: UUID) async throws -> DailyReport?
    func streak() async throws -> Streak
}
