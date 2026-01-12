//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// Defines a storage mechanism for authentication tokens.
///
/// `TokenStore` abstracts how authentication tokens are stored and retrieved,
/// allowing different persistence strategies to be implemented.
public protocol TokenStore: Sendable {

    /// Returns the currently stored token.
    ///
    /// - Returns: The current token, or `nil` if none is available.
    func currentToken() async -> String?

    /// Updates the stored token.
    ///
    /// - Parameter newToken: The new token to store.
    func updateToken(_ newToken: String) async
}
