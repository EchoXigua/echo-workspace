import SwiftUI

struct AppEnvironment {
    let apiClient: any APIClient
    let tokenStore: any TokenStore
    let localStore: any LocalStore
    let appleSignInAuthorizer: any AppleSignInAuthorizing
    let isLocalDebugLoginEnabled: Bool

    static let mock = AppEnvironment(
        apiClient: MockAPIClient(),
        tokenStore: InMemoryTokenStore(),
        localStore: InMemoryLocalStore(),
        appleSignInAuthorizer: MockAppleSignInAuthorizer(),
        isLocalDebugLoginEnabled: false
    )

    static func live(
        baseURL: URL,
        appleSignInAuthorizer: any AppleSignInAuthorizing = AppleSignInService(),
        isLocalDebugLoginEnabled: Bool = false
    ) -> AppEnvironment {
        let tokenStore = KeychainTokenStore(service: "app.leanmate.ios")
        return AppEnvironment(
            apiClient: LiveAPIClient(baseURL: baseURL, tokenStore: tokenStore),
            tokenStore: tokenStore,
            localStore: FileLocalStore(),
            appleSignInAuthorizer: appleSignInAuthorizer,
            isLocalDebugLoginEnabled: isLocalDebugLoginEnabled
        )
    }

    static func configured(processInfo: ProcessInfo = .processInfo) -> AppEnvironment {
        let appleSignInAuthorizer = configuredAppleSignInAuthorizer(processInfo: processInfo)

        if let baseURL = liveBaseURL(processInfo: processInfo) {
            return live(
                baseURL: baseURL,
                appleSignInAuthorizer: appleSignInAuthorizer,
                isLocalDebugLoginEnabled: localDebugLoginEnabled(for: baseURL)
            )
        }

        return AppEnvironment(
            apiClient: MockAPIClient(scenario: .profileIncomplete),
            tokenStore: InMemoryTokenStore(),
            localStore: FileLocalStore(),
            appleSignInAuthorizer: appleSignInAuthorizer,
            isLocalDebugLoginEnabled: false
        )
    }
}

private extension AppEnvironment {
    static func localDebugLoginEnabled(for baseURL: URL) -> Bool {
        #if DEBUG
        guard let host = baseURL.host?.lowercased() else {
            return false
        }
        return host == "127.0.0.1" || host == "localhost" || host == "::1"
        #else
        false
        #endif
    }

    static func liveBaseURL(processInfo: ProcessInfo) -> URL? {
        let environment = processInfo.environment
        if let value = environment["LEANMATE_API_BASE_URL"], let url = URL(string: value) {
            return url
        }

        let arguments = processInfo.arguments
        if let index = arguments.firstIndex(of: "-LeanMateAPIBaseURL"),
           arguments.indices.contains(index + 1),
           let url = URL(string: arguments[index + 1]) {
            return url
        }

        if environment["LEANMATE_API_MODE"] == "live" || arguments.contains("-LeanMateUseLiveAPI") {
            return URL(string: "http://127.0.0.1:8080")
        }

        return nil
    }

    static func configuredAppleSignInAuthorizer(processInfo: ProcessInfo) -> any AppleSignInAuthorizing {
        let environment = processInfo.environment
        if environment["LEANMATE_MOCK_APPLE_SIGN_IN"] == "1" ||
            processInfo.arguments.contains("-LeanMateMockAppleSignIn") {
            return MockAppleSignInAuthorizer()
        }

        return AppleSignInService()
    }
}

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment.mock
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
