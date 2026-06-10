import SwiftUI

struct AppEnvironment {
    let apiClient: any APIClient
    let tokenStore: any TokenStore
    let localStore: any LocalStore

    static let mock = AppEnvironment(
        apiClient: MockAPIClient(),
        tokenStore: InMemoryTokenStore(),
        localStore: InMemoryLocalStore()
    )

    static func live(baseURL: URL) -> AppEnvironment {
        let tokenStore = KeychainTokenStore(service: "app.leanmate.ios")
        return AppEnvironment(
            apiClient: LiveAPIClient(baseURL: baseURL, tokenStore: tokenStore),
            tokenStore: tokenStore,
            localStore: FileLocalStore()
        )
    }

    static func configured(processInfo: ProcessInfo = .processInfo) -> AppEnvironment {
        if let baseURL = liveBaseURL(processInfo: processInfo) {
            return live(baseURL: baseURL)
        }

        return AppEnvironment(
            apiClient: MockAPIClient(scenario: .profileIncomplete),
            tokenStore: InMemoryTokenStore(),
            localStore: FileLocalStore()
        )
    }
}

private extension AppEnvironment {
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
