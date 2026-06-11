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
    static let defaultLocalAppleIdentityToken = MockAppleSignInAuthorizer.defaultIdentityToken

    private let apiClient: any APIClient
    private let tokenStore: any TokenStore
    private let localStore: any LocalStore
    private let appleSignInAuthorizer: any AppleSignInAuthorizing

    @Published private(set) var state: OnboardingState = .idle
    @Published private(set) var hasAcceptedAgreement = false
    @Published private(set) var agreementMessage: String?

    var isLoggingIn: Bool {
        if case .loggingIn = state {
            return true
        }
        return false
    }

    init(
        apiClient: any APIClient,
        tokenStore: any TokenStore,
        localStore: any LocalStore,
        appleSignInAuthorizer: any AppleSignInAuthorizing = MockAppleSignInAuthorizer()
    ) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
        self.localStore = localStore
        self.appleSignInAuthorizer = appleSignInAuthorizer
    }

    func toggleAgreement() {
        hasAcceptedAgreement.toggle()
        if hasAcceptedAgreement {
            agreementMessage = nil
        }
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

    func signInWithApple() async -> OnboardingDestination? {
        guard !isLoggingIn else {
            return nil
        }

        guard hasAcceptedAgreement else {
            agreementMessage = "请先阅读并同意用户协议和隐私政策"
            return nil
        }

        state = .loggingIn
        agreementMessage = nil

        do {
            let credential = try await appleSignInAuthorizer.signIn()
            return try await loginAndSyncGuestData(
                identityToken: credential.identityToken,
                authorizationCode: credential.authorizationCode
            )
        } catch {
            await handleLoginFailure(error)
            return nil
        }
    }

    func mockLoginAndSyncGuestData() async -> OnboardingDestination? {
        guard !isLoggingIn else {
            return nil
        }

        state = .loggingIn

        do {
            return try await loginAndSyncGuestData(
                identityToken: localAppleIdentityToken,
                authorizationCode: nil
            )
        } catch {
            await handleLoginFailure(error)
            return nil
        }
    }
}

private extension OnboardingViewModel {
    var localAppleIdentityToken: String {
        let processInfo = ProcessInfo.processInfo
        if let value = processInfo.environment["LEANMATE_DEV_IDENTITY_TOKEN"] {
            return value
        }

        let arguments = processInfo.arguments
        if let index = arguments.firstIndex(of: "-LeanMateDevIdentityToken"),
           arguments.indices.contains(index + 1) {
            return arguments[index + 1]
        }

        return Self.defaultLocalAppleIdentityToken
    }

    func loginAndSyncGuestData(
        identityToken: String,
        authorizationCode: String?
    ) async throws -> OnboardingDestination {
        let token = try await apiClient.oauthLogin(
            OAuthLoginRequest(
                provider: .apple,
                identityToken: identityToken,
                authorizationCode: authorizationCode,
                deviceId: nil
            )
        )
        try await tokenStore.saveTokens(
            AuthTokens(accessToken: token.accessToken, refreshToken: token.refreshToken)
        )
        try await syncGuestDataIfNeeded()
        state = .idle
        return token.profileCompleted ? .home : .profileSetup
    }

    func handleLoginFailure(_ error: Error) async {
        if case .unauthorized = AppError(error) {
            try? await tokenStore.clearTokens()
        }

        state = .loginFailed(loginFailureMessage(for: error))
    }

    func loginFailureMessage(for error: Error) -> String {
        if let appleError = error as? AppleSignInError {
            switch appleError {
            case .cancelled, .authorizationFailed:
                return "Apple 登录未完成，请重试或先随便看看。"
            case .authorizationInProgress:
                return "Apple 登录正在处理中，请稍候。"
            case .invalidCredential, .missingIdentityToken:
                return "Apple 登录信息无效，请重试。"
            }
        }

        let appError = AppError(error)
        return appError.errorDescription ?? "Apple 登录未完成，请重试或先随便看看。"
    }

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
