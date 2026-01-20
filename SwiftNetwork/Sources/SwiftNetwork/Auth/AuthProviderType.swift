//
//  AuthProviderType.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Foundation

/// Identifies the authentication provider type.
///
/// `AuthProviderType` allows tracking which authentication mechanism
/// was used to obtain credentials, which is useful for analytics,
/// logging, and provider-specific logic.
public enum AuthProviderType: Sendable, Equatable, Hashable {
    
    /// Apple Sign In authentication.
    case apple
    
    /// Google OAuth authentication.
    case google
    
    /// The human-readable name of the provider.
    public var displayName: String {
        switch self {
        case .apple: return "Apple"
        case .google: return "Google"
        }
    }
}
