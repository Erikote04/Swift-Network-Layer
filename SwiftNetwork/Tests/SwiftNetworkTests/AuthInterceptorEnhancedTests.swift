//
//  AuthInterceptorEnhancedTests.swift
//  SwiftNetworkTests
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Enhanced Auth Interceptor Tests", .tags(.auth))
struct AuthInterceptorEnhancedTests {
    
    @Test("Auth interceptor with manager injects token")
    func interceptorWithManagerInjectsToken() async throws {
        let tokenStore = InMemoryTokenStore()
        let manager = AuthManager(tokenStore: tokenStore)
        
        let provider = MockAuthProvider(
            credentials: AuthCredentials(
                accessToken: "test_token",
                provider: .apple
            )
        )
        
        _ = try await manager.login(provider: provider)
        
        let interceptor = AuthInterceptor(authManager: manager)
        let transport = RecordingTransport()
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [interceptor]
        )
        
        let request = Request(method: .get, url: URL(string: "https://example.com")!)
        _ = try await client.newCall(request).execute()
        
        let recordedRequest = await transport.lastRequest
        #expect(recordedRequest?.headers["Authorization"] == "Bearer test_token")
    }
    
    @Test("Auth interceptor refreshes token on 401")
    func interceptorRefreshesOn401() async throws {
        let tokenStore = InMemoryTokenStore()
        let manager = AuthManager(tokenStore: tokenStore)
        let refreshCounter = RefreshCounter()
        
        await manager.setRefreshProvider { refreshToken in
            await refreshCounter.increment()
            return AuthCredentials(
                accessToken: "refreshed_token",
                refreshToken: refreshToken,
                provider: .google
            )
        }
        
        let provider = MockAuthProvider(
            credentials: AuthCredentials(
                accessToken: "expired_token",
                refreshToken: "refresh",
                expiresIn: 3600,
                provider: .google
            )
        )
        
        _ = try await manager.login(provider: provider)
        
        let interceptor = AuthInterceptor(authManager: manager)
        let transport = Failing401ThenSuccessTransport()
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [interceptor]
        )
        
        let request = Request(method: .get, url: URL(string: "https://example.com")!)
        let response = try await client.newCall(request).execute()
        
        #expect(response.statusCode == 200)
        #expect(await refreshCounter.count == 1)
    }
}

// MARK: - Mocks

private struct MockAuthProvider: AuthProvider {
    let credentials: AuthCredentials
    
    func login() async throws -> AuthCredentials {
        credentials
    }
}

private actor RefreshCounter {
    private(set) var count = 0
    
    func increment() {
        count += 1
    }
}

private actor RecordingTransport: Transport {
    private(set) var lastRequest: Request?
    
    func execute(_ request: Request) async throws -> Response {
        lastRequest = request
        return Response(
            request: request,
            statusCode: 200,
            headers: [:],
            body: nil
        )
    }
}

private actor Failing401ThenSuccessTransport: Transport {
    private var callCount = 0
    
    func execute(_ request: Request) async throws -> Response {
        callCount += 1
        
        if callCount == 1 {
            return Response(
                request: request,
                statusCode: 401,
                headers: [:],
                body: nil
            )
        }
        
        return Response(
            request: request,
            statusCode: 200,
            headers: [:],
            body: Data("success".utf8)
        )
    }
}
