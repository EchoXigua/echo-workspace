import Foundation
import Security

final class KeychainTokenStore: TokenStore, @unchecked Sendable {
    private enum Account {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    private let service: String

    init(service: String) {
        self.service = service
    }

    func loadTokens() async throws -> AuthTokens? {
        guard
            let accessToken = try read(account: Account.accessToken),
            let refreshToken = try read(account: Account.refreshToken)
        else {
            return nil
        }

        return AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
    }

    func saveTokens(_ tokens: AuthTokens) async throws {
        try save(tokens.accessToken, account: Account.accessToken)
        try save(tokens.refreshToken, account: Account.refreshToken)
    }

    func clearTokens() async throws {
        try delete(account: Account.accessToken)
        try delete(account: Account.refreshToken)
    }
}

private extension KeychainTokenStore {
    func save(_ value: String, account: String) throws {
        try delete(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: Data(value.utf8)
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AppError.unknown
        }
    }

    func read(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess, let data = item as? Data else {
            throw AppError.unknown
        }

        return String(data: data, encoding: .utf8)
    }

    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AppError.unknown
        }
    }
}
