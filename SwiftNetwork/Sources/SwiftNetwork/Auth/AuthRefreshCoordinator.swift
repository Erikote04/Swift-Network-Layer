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
public actor AuthRefreshCoordinator {

    private var refreshTask: Task<String?, Error>? = nil
    private var lastRefreshTime: Date?
    private let minRefreshInterval: TimeInterval = 0.1 // 100ms debounce
    
    /// Creates a new refresh coordinator.
    public init() {}

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
    public func refreshIfNeeded(
        tokenStore: TokenStore,
        authenticate: @escaping @Sendable () async throws -> String?
    ) async throws -> String? {

        // If there's already a refresh in progress, wait for it
        if let task = refreshTask {
            return try await task.value
        }
        
        // Debounce: if we just refreshed recently, return current token
        if let lastRefresh = lastRefreshTime,
           Date().timeIntervalSince(lastRefresh) < minRefreshInterval {
            return await tokenStore.currentToken()
        }

        // Create and store the task BEFORE awaiting it
        let task = Task<String?, Error> {
            let token = try await authenticate()
            
            if let token = token {
                await tokenStore.updateToken(token)
            }
            
            return token
        }

        // Store the task immediately to prevent other calls from creating a new one
        refreshTask = task
        
        // Await the result
        let result: String?
        do {
            result = try await task.value
            lastRefreshTime = Date()
        } catch {
            refreshTask = nil
            throw error
        }
        
        // Clear the task after completion
        refreshTask = nil
        
        return result
    }
}
