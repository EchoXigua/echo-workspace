import Foundation
import Combine

enum OnboardingDestination: Equatable {
    case profileSetup
    case home
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

    @Published private(set) var state: OnboardingState = .idle

    var isLoggingIn: Bool {
        if case .loggingIn = state {
            return true
        }
        return false
    }

    init(apiClient: any APIClient, tokenStore: any TokenStore) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
    }

    func mockLogin() async -> OnboardingDestination? {
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
            state = .idle
            return token.profileCompleted ? .home : .profileSetup
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
