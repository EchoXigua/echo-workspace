import Foundation

enum PreviewEnvironment {
    static let success = AppEnvironment.mock

    static let empty = AppEnvironment(
        apiClient: MockAPIClient(scenario: .empty),
        tokenStore: InMemoryTokenStore(),
        localStore: InMemoryLocalStore(),
        appleSignInAuthorizer: MockAppleSignInAuthorizer(),
        isLocalDebugLoginEnabled: false
    )

    static let error = AppEnvironment(
        apiClient: MockAPIClient(scenario: .error(.networkUnavailable)),
        tokenStore: InMemoryTokenStore(),
        localStore: InMemoryLocalStore(),
        appleSignInAuthorizer: MockAppleSignInAuthorizer(),
        isLocalDebugLoginEnabled: false
    )
}
