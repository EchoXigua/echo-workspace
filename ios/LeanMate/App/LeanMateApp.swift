import SwiftUI

@main
struct LeanMateApp: App {
    private let environment = AppEnvironment(
        apiClient: MockAPIClient(scenario: .profileIncomplete),
        tokenStore: InMemoryTokenStore(),
        localStore: InMemoryLocalStore()
    )

    var body: some Scene {
        WindowGroup {
            AppRootView(environment: environment)
        }
    }
}
