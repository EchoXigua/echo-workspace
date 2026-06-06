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
