//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Foundation

/// Coordinates authentication token refresh operations.
///
/// `AuthRefreshCoordinator` ensures that only a single token refresh
/// operation is performed at a time, even when multiple requests
/// simultaneously encounter authentication failures.
actor AuthRefreshCoordinator {

    private var refreshTask: Task<String?, Error>? = nil

    /// Performs a token refresh operation if needed.
    ///
    /// If a refresh operation is already in progress, this method awaits
    /// the existing task instead of starting a new one.
    ///
    /// - Parameters:
    ///   - tokenStore: The token store to update with the refreshed token.
    ///   - authenticate: A closure responsible for performing authentication and returning a new token.
    /// - Returns: The refreshed token, or `nil` if refresh fails.
    /// - Throws: An error if authentication fails.
    func refreshIfNeeded(
        tokenStore: TokenStore,
        authenticate: @escaping @Sendable () async throws -> String?
    ) async throws -> String? {

        // If there's already a refresh in progress, wait for it
        if let task = refreshTask {
            return try await task.value
        }

        // Create and store the task BEFORE awaiting it
        let task = Task<String?, Error> {
            defer { 
                Task { await clearRefreshTask() }
            }

            guard let token = try await authenticate() else {
                return nil
            }

            await tokenStore.updateToken(token)
            return token
        }

        // Store the task immediately to prevent other calls from creating a new one
        refreshTask = task
        
        // Now await the result
        return try await task.value
    }
    
    /// Clears the current refresh task.
    ///
    /// This is called from the task's defer block to ensure proper cleanup.
    private func clearRefreshTask() {
        refreshTask = nil
    }
}
