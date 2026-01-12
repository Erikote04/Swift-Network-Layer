//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Foundation

/// An in-memory implementation of `TokenStore`.
///
/// `InMemoryTokenStore` stores authentication tokens in memory and
/// is suitable for simple use cases, testing, or ephemeral sessions.
public actor InMemoryTokenStore: TokenStore {

    private var token: String?

    /// Creates a new in-memory token store.
    ///
    /// - Parameter initialToken: An optional initial token.
    public init(initialToken: String? = nil) {
        self.token = initialToken
    }

    /// Returns the currently stored token.
    ///
    /// - Returns: The current token, or `nil` if none is stored.
    public func currentToken() async -> String? {
        token
    }

    /// Updates the stored token.
    ///
    /// - Parameter newToken: The new token to store.
    public func updateToken(_ newToken: String) async {
        token = newToken
    }
}
