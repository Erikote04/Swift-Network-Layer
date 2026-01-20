//
//  AuthError.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Foundation

/// Errors that can occur during authentication.
///
/// `AuthError` represents various failure modes in the authentication process,
/// from user cancellation to provider configuration issues.
public enum AuthError: Error, Sendable, Equatable {
    
    /// The user cancelled the authentication flow.
    case cancelled
    
    /// Authentication failed with an underlying error.
    ///
    /// - Parameter underlying: The original error that caused the failure.
    case authenticationFailed(underlying: Error?)
    
    /// The credentials received from the provider are invalid.
    case invalidCredentials
    
    /// The authentication provider is not properly configured.
    case providerNotConfigured
    
    /// The authentication method is not supported on this platform.
    case unsupportedPlatform
    
    public static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.cancelled, .cancelled),
             (.invalidCredentials, .invalidCredentials),
             (.providerNotConfigured, .providerNotConfigured),
             (.unsupportedPlatform, .unsupportedPlatform):
            return true
        case (.authenticationFailed, .authenticationFailed):
            return true
        default:
            return false
        }
    }
}
