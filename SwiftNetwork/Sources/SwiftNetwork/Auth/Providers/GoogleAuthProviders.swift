//
//  GoogleAuthProvider.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Foundation
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if canImport(UIKit)
import UIKit
#endif
import CommonCrypto

/// Provides authentication using Google OAuth 2.0.
///
/// `GoogleAuthProvider` implements OAuth 2.0 with PKCE (Proof Key for Code Exchange)
/// for secure authentication without requiring client secrets on mobile devices.
///
/// ## Topics
/// ### Configuration
/// - ``init(clientId:redirectURI:scopes:)``
/// ### Authentication
/// - ``login()``
@available(iOS 12.0, macOS 10.15, *)
public final class GoogleAuthProvider: NSObject, AuthProvider, Sendable {
    
    private let clientId: String
    private let redirectURI: String
    private let scopes: [String]
    
    /// Creates a new Google authentication provider.
    ///
    /// - Parameters:
    ///   - clientId: Your Google OAuth client ID.
    ///   - redirectURI: The redirect URI registered in Google Console.
    ///   - scopes: OAuth scopes to request (default: profile and email).
    public init(
        clientId: String,
        redirectURI: String,
        scopes: [String] = ["profile", "email"]
    ) {
        self.clientId = clientId
        self.redirectURI = redirectURI
        self.scopes = scopes
        super.init()
    }
    
    /// Performs Google OAuth authentication.
    ///
    /// This method initiates the OAuth flow using PKCE, presents a web view
    /// for user authorization, and exchanges the authorization code for tokens.
    ///
    /// - Returns: Authentication credentials containing access and refresh tokens.
    /// - Throws: ``AuthError`` if authentication fails or is cancelled.
    @MainActor
    public func login() async throws -> AuthCredentials {
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        
        let authURL = buildAuthorizationURL(codeChallenge: codeChallenge)
        
        #if os(iOS) && canImport(AuthenticationServices)
        let authCode = try await presentAuthenticationSession(url: authURL)
        #else
        throw AuthError.unsupportedPlatform
        #endif
        
        return try await exchangeCodeForToken(code: authCode, codeVerifier: codeVerifier)
    }
    
    // MARK: - PKCE Helpers
    
    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else {
            return verifier
        }
        var buffer = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &buffer)
        }
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func buildAuthorizationURL(codeChallenge: String) -> URL {
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        return components.url!
    }
    
    #if os(iOS) && canImport(AuthenticationServices)
    private func presentAuthenticationSession(url: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: URL(string: redirectURI)?.scheme
            ) { callbackURL, error in
                if let error = error {
                    let authError = (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin
                        ? AuthError.cancelled
                        : AuthError.authenticationFailed(underlying: error)
                    continuation.resume(throwing: authError)
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: AuthError.invalidCredentials)
                    return
                }
                
                continuation.resume(returning: code)
            }
            
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
    }
    #endif
    
    private func exchangeCodeForToken(code: String, codeVerifier: String) async throws -> AuthCredentials {
        var components = URLComponents(string: "https://oauth2.googleapis.com/token")!
        
        let bodyParams = [
            "code": code,
            "client_id": clientId,
            "code_verifier": codeVerifier,
            "redirect_uri": redirectURI,
            "grant_type": "authorization_code"
        ]
        
        let bodyString = bodyParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.authenticationFailed(underlying: nil)
        }
        
        let tokenResponse = try JSONDecoder().decode(GoogleTokenResponse.self, from: data)
        
        return AuthCredentials(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            expiresIn: TimeInterval(tokenResponse.expiresIn),
            provider: .google
        )
    }
}

#if os(iOS) && canImport(AuthenticationServices)
extension GoogleAuthProvider: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}
#endif

// MARK: - Supporting Types

private struct GoogleTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}
