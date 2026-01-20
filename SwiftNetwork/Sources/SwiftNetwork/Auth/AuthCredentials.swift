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
    
    /// Optional expiration time in seconds from issuance.
    public let expiresIn: TimeInterval?
    
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
        self.expiresIn = expiresIn
        self.provider = provider
    }
}
