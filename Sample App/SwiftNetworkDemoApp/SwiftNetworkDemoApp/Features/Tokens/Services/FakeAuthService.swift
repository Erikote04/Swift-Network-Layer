//
//  FakeAuthService.swift
//  SwiftNetworkDemo
//
//  Simulates an authentication service with token refresh
//

import Foundation
import SwiftNetwork

/// Simulates an authentication service with automatic token expiration
actor FakeAuthService {
    
    // MARK: - Properties
    
    private var currentToken: String?
    private var tokenExpirationDate: Date?
    private var refreshCount = 0
    
    /// Callback for token refresh events (for UI updates)
    private var onTokenRefresh: (@Sendable (String) -> Void)?
    
    // MARK: - Public Methods
    
    /// Sets the callback for token refresh events
    func setTokenRefreshCallback(_ callback: @escaping @Sendable (String) -> Void) {
        self.onTokenRefresh = callback
    }
    
    // MARK: - Token Management
    
    /// Returns the current token, or nil if expired
    func getCurrentToken() -> String? {
        guard let token = currentToken,
              let expirationDate = tokenExpirationDate,
              Date() < expirationDate else {
            return nil
        }
        return token
    }
    
    /// Stores a new token with an expiration time
    func storeToken(_ token: String, expiresIn seconds: TimeInterval = 10) {
        self.currentToken = token
        self.tokenExpirationDate = Date().addingTimeInterval(seconds)
        print("🔐 Token stored: \(token) (expires in \(seconds)s)")
    }
    
    /// Simulates a token refresh operation
    func refreshToken() async throws -> String {
        print("🔄 Starting token refresh...")
        
        // Simulate network delay
        try await Task.sleep(for: .seconds(2))
        
        refreshCount += 1
        let newToken = "token_\(refreshCount)_\(UUID().uuidString.prefix(8))"
        
        // Store with 10 second expiration for demo purposes
        storeToken(newToken, expiresIn: 10)
        
        // Notify observers
        onTokenRefresh?(newToken)
        
        print("✅ Token refreshed: \(newToken)")
        
        return newToken
    }
    
    /// Invalidates the current token (for testing)
    func invalidateToken() {
        print("❌ Token invalidated")
        self.currentToken = nil
        self.tokenExpirationDate = nil
    }
    
    /// Resets the service to initial state
    func reset() {
        currentToken = nil
        tokenExpirationDate = nil
        refreshCount = 0
    }
}
