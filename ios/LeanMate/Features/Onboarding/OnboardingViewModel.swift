import Foundation
import Combine

enum OnboardingDestination: Equatable {
    case profileSetup
    case home
    case visitorHome
}

enum OnboardingState: Equatable {
    case idle
    case loggingIn
    case loginFailed(String)
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    private let apiClient: any APIClient
    private let tokenStore: any TokenStore
    private let localStore: any LocalStore

    @Published private(set) var state: OnboardingState = .idle

    var isLoggingIn: Bool {
        if case .loggingIn = state {
            return true
        }
        return false
    }

    init(apiClient: any APIClient, tokenStore: any TokenStore, localStore: any LocalStore) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
        self.localStore = localStore
    }

    func startGuestSession() async -> OnboardingDestination? {
        guard !isLoggingIn else {
            return nil
        }

        state = .loggingIn

        do {
            let now = Date()
            try await localStore.saveGuestSession(GuestSession(startedAt: now, updatedAt: now))
            state = .idle
            return .visitorHome
        } catch {
            state = .loginFailed(AppError(error).errorDescription ?? "本地模式启动失败，请稍后重试")
            return nil
        }
    }

    func mockLoginAndSyncGuestData() async -> OnboardingDestination? {
        guard !isLoggingIn else {
            return nil
        }

        state = .loggingIn

        do {
            let token = try await apiClient.oauthLogin(
                OAuthLoginRequest(
                    provider: .apple,
                    identityToken: "mock-apple-identity-token",
                    authorizationCode: nil,
                    deviceId: nil
                )
            )
            try await tokenStore.saveTokens(
                AuthTokens(accessToken: token.accessToken, refreshToken: token.refreshToken)
            )
            try await syncGuestDataIfNeeded()
            state = .idle
            return .home
        } catch {
            let appError = AppError(error)
            if case .unauthorized = appError {
                try? await tokenStore.clearTokens()
            }
            state = .loginFailed(appError.errorDescription ?? "登录失败，请稍后重试")
            return nil
        }
    }
}

private extension OnboardingViewModel {
    func syncGuestDataIfNeeded() async throws {
        if let profile = try await localStore.localProfile() {
            _ = try await apiClient.saveProfile(
                SaveUserProfileRequest(
                    gender: profile.gender,
                    age: profile.age,
                    heightCm: profile.heightCm,
                    currentWeightKg: profile.currentWeightKg,
                    targetWeightKg: profile.targetWeightKg,
                    activityLevel: profile.activityLevel,
                    timezone: profile.timezone,
                    targetDate: profile.targetDate
                )
            )
        }

        for entry in try await localStore.allLocalDietEntries() {
            _ = try await apiClient.saveDietEntry(
                SaveFoodEntryRequest(
                    recognitionTaskId: entry.recognitionTaskId,
                    mealDate: entry.mealDate,
                    mealType: entry.mealType,
                    sourceType: entry.sourceType,
                    rawText: entry.rawText,
                    imageUrl: entry.imageUrl,
                    items: entry.items.map {
                        SaveFoodItemRequest(
                            id: $0.id,
                            name: $0.name,
                            quantityText: $0.quantityText,
                            weightG: $0.weightG,
                            caloriesKcal: $0.caloriesKcal,
                            proteinG: $0.proteinG,
                            fatG: $0.fatG,
                            carbsG: $0.carbsG,
                            confidence: $0.confidence,
                            userEdited: $0.userEdited
                        )
                    }
                )
            )
        }

        for weight in try await localStore.localWeightEntries() {
            _ = try await apiClient.saveWeight(
                SaveWeightEntryRequest(
                    recordDate: weight.recordDate,
                    weightKg: weight.weightKg,
                    note: weight.note
                )
            )
        }

        try await localStore.clearGuestSession()
    }
}
