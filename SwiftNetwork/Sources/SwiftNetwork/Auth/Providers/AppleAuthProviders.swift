//
//  AppleAuthProvider.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

#if canImport(AuthenticationServices)
import Foundation
import AuthenticationServices
import CryptoKit

/// Provides authentication using Apple Sign In.
///
/// `AppleAuthProvider` implements Sign in with Apple, handling the authorization
/// flow, nonce generation, and credential exchange.
///
/// ## Topics
/// ### Configuration
/// - ``init(scopes:)``
/// ### Authentication
/// - ``login()``
@available(iOS 13.0, macOS 10.15, *)
public final class AppleAuthProvider: NSObject, AuthProvider, Sendable {
    
    private let scopes: [ASAuthorization.Scope]
    private let continuation: ManagedContinuation<AuthCredentials>
    
    /// Creates a new Apple authentication provider.
    ///
    /// - Parameter scopes: The authorization scopes to request (e.g., `.fullName`, `.email`).
    public init(scopes: [ASAuthorization.Scope] = [.fullName, .email]) {
        self.scopes = scopes
        self.continuation = ManagedContinuation()
        super.init()
    }
    
    /// Performs Apple Sign In authentication.
    ///
    /// This method presents the Apple Sign In sheet, handles user authorization,
    /// and returns credentials upon successful authentication.
    ///
    /// - Returns: Authentication credentials containing the identity token.
    /// - Throws: ``AuthError`` if authentication fails or is cancelled.
    @MainActor
    public func login() async throws -> AuthCredentials {
        let nonce = generateNonce()
        let hashedNonce = sha256(nonce)
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = scopes
        request.nonce = hashedNonce
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        
        #if os(iOS)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            controller.presentationContextProvider = WindowContextProvider(window: window)
        }
        #endif
        
        controller.performRequests()
        
        return try await continuation.value
    }
    
    // MARK: - Private Helpers
    
    private func generateNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

@available(iOS 13.0, macOS 10.15, *)
extension AppleAuthProvider: ASAuthorizationControllerDelegate {
    
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            Task { await continuation.resume(throwing: AuthError.invalidCredentials) }
            return
        }
        
        let authCredentials = AuthCredentials(
            accessToken: tokenString,
            refreshToken: nil,
            expiresIn: nil,
            provider: .apple
        )
        
        Task { await continuation.resume(returning: authCredentials) }
    }
    
    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let authError: AuthError
        if let asError = error as? ASAuthorizationError {
            switch asError.code {
            case .canceled:
                authError = .cancelled
            case .failed:
                authError = .authenticationFailed(underlying: error)
            case .invalidResponse:
                authError = .invalidCredentials
            case .notHandled:
                authError = .providerNotConfigured
            case .unknown:
                authError = .authenticationFailed(underlying: error)
            @unknown default:
                authError = .authenticationFailed(underlying: error)
            }
        } else {
            authError = .authenticationFailed(underlying: error)
        }
        
        Task { await continuation.resume(throwing: authError) }
    }
}

// MARK: - Supporting Types

#if os(iOS)
@available(iOS 13.0, *)
private final class WindowContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    private let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        window
    }
}
#endif
#endif
