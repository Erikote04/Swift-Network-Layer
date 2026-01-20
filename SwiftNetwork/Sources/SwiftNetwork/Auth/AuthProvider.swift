//
//  AuthProvider.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Foundation

/// Defines a mechanism for performing authentication.
///
/// `AuthProvider` abstracts the authentication process, allowing different
/// authentication strategies (OAuth, social login, custom flows) to be
/// implemented in a unified way.
public protocol AuthProvider: Sendable {
    
    /// Performs an authentication flow.
    ///
    /// This method initiates the authentication process specific to the provider
    /// (e.g., OAuth flow, credential validation) and returns the resulting credentials.
    ///
    /// - Returns: Authentication credentials containing tokens and provider information.
    /// - Throws: An error if authentication fails or is cancelled.
    func login() async throws -> AuthCredentials
}
