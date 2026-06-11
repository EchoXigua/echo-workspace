import Foundation

enum OAuthProvider: String, Codable, Sendable {
    case apple
    case google
}

enum UserStatus: String, Codable, Sendable {
    case active
    case disabled
    case deleted
}

enum Gender: String, Codable, CaseIterable, Identifiable, Sendable {
    case male
    case female
    case unknown

    var id: String { rawValue }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable, Sendable {
    case sedentary
    case light
    case moderate
    case active
    case veryActive = "very_active"

    var id: String { rawValue }
}

enum MealType: String, Codable, CaseIterable, Identifiable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack

    var id: String { rawValue }
}

enum FoodSourceType: String, Codable, Sendable {
    case photo
    case text
    case manual
}

enum RecognitionStatus: String, Codable, Sendable {
    case pending
    case running
    case succeeded
    case failed
}

enum FoodEntryStatus: String, Codable, Sendable {
    case draft
    case confirmed
    case deleted
}

enum DailyReportStatus: String, Codable, Sendable {
    case pending
    case generated
    case viewed
    case failed
}

struct OAuthLoginRequest: Encodable, Sendable {
    let provider: OAuthProvider
    let identityToken: String
    let authorizationCode: String?
    let deviceId: String?
}

struct RefreshTokenRequest: Encodable, Sendable {
    let refreshToken: String
}

struct LogoutRequest: Encodable, Sendable {
    let refreshToken: String?
}

struct AuthToken: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let user: CurrentUser
    let profileCompleted: Bool
}

struct CurrentUser: Codable, Identifiable, Sendable {
    let id: UUID
    let nickname: String?
    let avatarUrl: String?
    let status: UserStatus
    let profileCompleted: Bool
    let createdAt: Date
}

struct SaveUserProfileRequest: Codable, Sendable {
    let gender: Gender
    let age: Int
    let heightCm: Double
    let currentWeightKg: Double
    let targetWeightKg: Double
    let activityLevel: ActivityLevel
    let timezone: String
    let targetDate: Date?
}

struct ProfilePayload: Codable, Sendable {
    let profileCompleted: Bool
    let profile: UserProfile?
}

struct UserProfile: Codable, Sendable {
    let gender: Gender
    let age: Int
    let heightCm: Double
    let currentWeightKg: Double
    let targetWeightKg: Double
    let activityLevel: ActivityLevel
    let timezone: String
    let targetDate: Date?
    let bmi: Double
    let bmrKcal: Int
    let dailyCalorieTargetKcal: Int
}

struct TodayHome: Codable, Sendable {
    let date: Date
    let profileCompleted: Bool
    let calorieTargetKcal: Int
    let caloriesInKcal: Int
    let remainingCaloriesKcal: Int
    let proteinG: Double?
    let fatG: Double?
    let carbsG: Double?
    let currentWeightKg: Double?
    let streakDays: Int
    let reportSummary: String?
    let foodEntries: [FoodEntrySummary]
}

struct TextRecognitionRequest: Codable, Sendable {
    let text: String
    let mealType: MealType
    let mealDate: Date?
}

struct RecognitionTask: Codable, Identifiable, Sendable {
    let id: UUID
    let sourceType: FoodSourceType
    let mealDate: Date?
    let mealType: MealType?
    let status: RecognitionStatus
    let draftEntry: FoodEntryDraft?
    let errorCode: String?
    let errorMessage: String?
    let createdAt: Date
    let finishedAt: Date?
}

struct FoodEntryDraft: Codable, Sendable {
    let mealDate: Date
    let mealType: MealType
    let sourceType: FoodSourceType
    let items: [FoodItem]
}

struct SaveFoodEntryRequest: Codable, Sendable {
    let recognitionTaskId: UUID?
    let mealDate: Date
    let mealType: MealType
    let sourceType: FoodSourceType
    let rawText: String?
    let imageUrl: String?
    let items: [SaveFoodItemRequest]
}

struct SaveFoodItemRequest: Codable, Sendable {
    let id: UUID?
    let name: String
    let quantityText: String?
    let weightG: Double?
    let caloriesKcal: Int?
    let proteinG: Double?
    let fatG: Double?
    let carbsG: Double?
    let confidence: Double?
    let userEdited: Bool?
}

struct FoodEntry: Codable, Identifiable, Sendable {
    let id: UUID
    let recognitionTaskId: UUID?
    let mealDate: Date
    let mealType: MealType
    let sourceType: FoodSourceType
    let rawText: String?
    let imageUrl: String?
    let status: FoodEntryStatus
    let totalCaloriesKcal: Int
    let totalProteinG: Double
    let totalFatG: Double
    let totalCarbsG: Double
    let items: [FoodItem]
    let createdAt: Date?
}

struct FoodEntrySummary: Codable, Identifiable, Sendable {
    let id: UUID
    let mealType: MealType
    let totalCaloriesKcal: Int
    let itemNames: [String]
}

struct FoodEntrySaveResult: Codable, Sendable {
    let entry: FoodEntry
    let today: DailyNutritionSnapshot
}

struct FoodItem: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let quantityText: String?
    let weightG: Double?
    let caloriesKcal: Int?
    let proteinG: Double?
    let fatG: Double?
    let carbsG: Double?
    let confidence: Double?
    let userEdited: Bool
}

struct SaveWeightEntryRequest: Codable, Sendable {
    let recordDate: Date
    let weightKg: Double
    let note: String?
}

struct WeightEntry: Codable, Identifiable, Sendable {
    let recordDate: Date
    let weightKg: Double
    let note: String?
    let id: UUID
    let createdAt: Date
}

struct WeightEntrySaveResult: Codable, Sendable {
    let entry: WeightEntry
    let today: DailyNutritionSnapshot
}

struct DailyNutritionSnapshot: Codable, Sendable {
    let date: Date
    let calorieTargetKcal: Int
    let caloriesKcal: Int
    let remainingCaloriesKcal: Int
    let proteinG: Double
    let fatG: Double
    let carbsG: Double
    let foodEntryCount: Int
    let weightKg: Double?
}

struct GenerateDailyReportRequest: Codable, Sendable {
    let date: Date?
}

struct DailyReport: Codable, Identifiable, Sendable {
    let id: UUID
    let reportDate: Date
    let score: Int?
    let summary: String?
    let problem: String?
    let suggestion: String?
    let status: DailyReportStatus
    let generatedAt: Date?
    let viewedAt: Date?
}

struct Streak: Codable, Sendable {
    let currentDays: Int
    let longestDays: Int
    let lastActiveDate: Date?
    let milestones: [StreakMilestone]
}

struct StreakMilestone: Codable, Identifiable, Sendable {
    var id: Int { days }

    let days: Int
    let achieved: Bool
    let achievedAt: Date?
}

struct RetentionNotice: Codable, Identifiable, Sendable {
    let id: UUID
    let type: String
    let title: String
    let message: String?
    let currentValue: Int
    let previousValue: Int?
    let nextValue: Int?
    let triggeredAt: Date
}
