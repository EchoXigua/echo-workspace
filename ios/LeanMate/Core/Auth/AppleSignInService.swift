import AuthenticationServices
import UIKit

struct AppleSignInCredential: Equatable, Sendable {
    let identityToken: String
    let authorizationCode: String?
}

enum AppleSignInError: Error, Sendable {
    case cancelled
    case authorizationInProgress
    case authorizationFailed
    case invalidCredential
    case missingIdentityToken
}

protocol AppleSignInAuthorizing: AnyObject {
    @MainActor
    func signIn() async throws -> AppleSignInCredential
}

final class AppleSignInService: NSObject, AppleSignInAuthorizing {
    private var continuation: CheckedContinuation<AppleSignInCredential, Error>?

    @MainActor
    func signIn() async throws -> AppleSignInCredential {
        guard continuation == nil else {
            throw AppleSignInError.authorizationInProgress
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            finish(with: .failure(AppleSignInError.invalidCredential))
            return
        }

        guard let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8),
              !identityToken.isEmpty else {
            finish(with: .failure(AppleSignInError.missingIdentityToken))
            return
        }

        let authorizationCode = credential.authorizationCode.flatMap {
            String(data: $0, encoding: .utf8)
        }

        finish(
            with: .success(
                AppleSignInCredential(
                    identityToken: identityToken,
                    authorizationCode: authorizationCode
                )
            )
        )
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authorizationError = error as? ASAuthorizationError {
            if authorizationError.code == .canceled {
                finish(with: .failure(AppleSignInError.cancelled))
            } else {
                finish(with: .failure(AppleSignInError.authorizationFailed))
            }
            return
        }

        finish(with: .failure(error))
    }
}

extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

private extension AppleSignInService {
    func finish(with result: Result<AppleSignInCredential, Error>) {
        guard let continuation else {
            return
        }

        self.continuation = nil
        continuation.resume(with: result)
    }
}

final class MockAppleSignInAuthorizer: AppleSignInAuthorizing {
    static let defaultIdentityToken = "mock:ios-local-user:ios-local@leanmate.local"

    private let result: Result<AppleSignInCredential, Error>

    init(
        result: Result<AppleSignInCredential, Error> = .success(
            AppleSignInCredential(
                identityToken: MockAppleSignInAuthorizer.defaultIdentityToken,
                authorizationCode: "mock-authorization-code"
            )
        )
    ) {
        self.result = result
    }

    @MainActor
    func signIn() async throws -> AppleSignInCredential {
        switch result {
        case .success(let credential):
            return credential
        case .failure(let error):
            throw error
        }
    }
}
