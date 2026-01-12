//
//  FakeAuthenticator.swift
//  SwiftNetworkDemo
//
//  Authenticator implementation for demonstration purposes
//

import Foundation
import SwiftNetwork

/// Authenticator that handles 401 responses by refreshing tokens
struct FakeAuthenticator: Authenticator {
    
    let tokenStore: TokenStore
    let authService: FakeAuthService
    
    /// Callback for authentication events (for UI updates)
    let onAuthEvent: @Sendable (String) -> Void
    
    func authenticate(request: Request, response: Response) async throws -> Request? {
        // Only handle 401 Unauthorized
        guard response.statusCode == 401 else {
            return nil
        }
        
        onAuthEvent("🔒 401 detected - attempting token refresh...")
        
        // Refresh the token
        let newToken = try await authService.refreshToken()
        
        // Store it using the correct method
        await tokenStore.updateToken(newToken)
        
        onAuthEvent("✅ Token refreshed successfully")
        
        // Create new request with updated token
        var headers = request.headers
        headers["Authorization"] = "Bearer \(newToken)"
        
        return Request(
            method: request.method,
            url: request.url,
            headers: headers,
            body: request.body,
            timeout: request.timeout,
            cachePolicy: request.cachePolicy
        )
    }
}
