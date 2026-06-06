import Foundation

struct AuthTokens: Codable, Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
}

protocol TokenStore: Sendable {
    func loadTokens() async throws -> AuthTokens?
    func saveTokens(_ tokens: AuthTokens) async throws
    func clearTokens() async throws
}

actor InMemoryTokenStore: TokenStore {
    private var tokens: AuthTokens?

    func loadTokens() async throws -> AuthTokens? {
        tokens
    }

    func saveTokens(_ tokens: AuthTokens) async throws {
        self.tokens = tokens
    }

    func clearTokens() async throws {
        tokens = nil
    }
}
