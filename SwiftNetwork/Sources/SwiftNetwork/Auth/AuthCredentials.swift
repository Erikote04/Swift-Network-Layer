//
//  AuthCredentials.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Foundation

/// Represents authentication credentials obtained from an auth provider.
///
/// `AuthCredentials` encapsulates the tokens and metadata required
/// to authenticate subsequent network requests.
public struct AuthCredentials: Sendable, Equatable {
    
    /// The access token used to authenticate requests.
    public let accessToken: String
    
    /// An optional refresh token used to obtain new access tokens.
    public let refreshToken: String?
    
    /// Optional token expiration information.
    public let expiration: TokenExpiration?
    
    /// The provider that issued these credentials.
    public let provider: AuthProviderType
    
    /// Creates new authentication credentials.
    ///
    /// - Parameters:
    ///   - accessToken: The access token.
    ///   - refreshToken: Optional refresh token.
    ///   - expiresIn: Optional expiration time in seconds.
    ///   - provider: The authentication provider type.
    public init(
        accessToken: String,
        refreshToken: String? = nil,
        expiresIn: TimeInterval? = nil,
        provider: AuthProviderType
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = expiresIn.map { TokenExpiration(expiresIn: $0) }
        self.provider = provider
    }
    
    /// Whether the access token has expired.
    ///
    /// - Parameter date: The reference date (defaults to now).
    /// - Returns: `true` if the token has expired, or `false` if no expiration info is available.
    public func isExpired(at date: Date = Date()) -> Bool {
        expiration?.isExpired(at: date) ?? false
    }
    
    /// Whether the access token is expiring soon.
    ///
    /// - Parameters:
    ///   - threshold: How many seconds before expiration to consider "soon" (default: 300).
    ///   - date: The reference date (defaults to now).
    /// - Returns: `true` if the token expires within the threshold.
    public func isExpiringSoon(threshold: TimeInterval = 300, at date: Date = Date()) -> Bool {
        expiration?.isExpiringSoon(threshold: threshold, at: date) ?? false
    }
}
