//
//  TokenDemoViewModel.swift
//  SwiftNetworkDemo
//
//  ViewModel demonstrating concurrent requests with token refresh coordination
//

import Foundation
import SwiftNetwork

@Observable
final class TokenDemoViewModel {
    
    // MARK: - Published State
    
    var requests: [RequestState] = []
    var currentToken: String?
    var tokenRefreshLog: [String] = []
    var isRunning = false
    var totalRefreshes = 0
    
    // MARK: - Dependencies
    
    private let authService = FakeAuthService()
    private let tokenStore = InMemoryTokenStore()
    private var networkClient: NetworkClient?
    
    // MARK: - Initialization
    
    init() {
        setupTokenRefreshCallback()
    }
    
    // MARK: - Public Methods
    
    /// Runs a demo with multiple concurrent requests
    @MainActor
    func runDemo(requestCount: Int = 5) async {
        guard !isRunning else { return }
        
        isRunning = true
        reset()
        
        // IMPORTANT: Initialize with an INVALID token (not starting with "token_")
        // This ensures AuthInterceptor will add it to requests
        await tokenStore.updateToken("invalid_token")
        
        addLog("🚀 Starting demo with \(requestCount) concurrent requests")
        addLog("❌ Token is currently INVALID")
        
        // Create initial request states
        requests = (1...requestCount).map { RequestState(requestNumber: $0) }
        
        // Setup network client with auth interceptor
        setupNetworkClient()
        
        // Launch all requests concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<requestCount {
                group.addTask {
                    await self.executeRequest(index: i)
                }
            }
        }
        
        addLog("✅ All requests completed!")
        addLog("📊 Total token refreshes: \(totalRefreshes)")
        
        isRunning = false
    }
    
    /// Invalidates the current token manually
    @MainActor
    func invalidateToken() async {
        await tokenStore.updateToken("invalid_token")
        currentToken = nil
        addLog("🔓 Token manually invalidated")
    }
    
    // MARK: - Private Methods
    
    private func setupTokenRefreshCallback() {
        Task {
            await authService.setTokenRefreshCallback { [weak self] newToken in
                guard let self = self else { return }
                Task { @MainActor in
                    self.currentToken = newToken
                    self.totalRefreshes += 1
                }
            }
        }
    }
    
    private func setupNetworkClient() {
        let authenticator = FakeAuthenticator(
            tokenStore: tokenStore,
            authService: authService
        ) { event in
            Task { @MainActor in
                self.addLog(event)
            }
        }
        
        let config = NetworkClientConfiguration(
            baseURL: URL(string: "https://rickandmortyapi.com/api")!,
            interceptors: [
                // IMPORTANT: Order is critical!
                
                // 1. AuthInterceptor FIRST - adds token from store
                AuthInterceptor(
                    tokenStore: tokenStore,
                    authenticator: authenticator
                ),
                
                // 2. THEN Fake401Interceptor - checks if token is invalid and returns 401
                //    This runs AFTER AuthInterceptor adds the token
                //    So it can check the Authorization header
                Fake401Interceptor()
            ]
        )
        
        networkClient = NetworkClient(configuration: config)
    }
    
    @MainActor
    private func executeRequest(index: Int) async {
        guard index < requests.count else { return }
        
        let requestNumber = requests[index].requestNumber
        
        // Update status: executing
        requests[index].updateStatus(.executing, message: "Request #\(requestNumber) executing...")
        
        do {
            // IMPORTANT: Don't add token here - let the interceptor handle it
            // This way, if token is invalid, we'll get 401
            let request = Request(
                method: .get,
                url: URL(string: "/character/1")!
            )
            
            // Use plain execute() NOT execute<T>() to avoid automatic validation
            // We want the interceptor to see the 401 response before validation
            let response = try await networkClient!.newCall(request).execute()
            
            // Now validate manually
            if response.statusCode == 401 {
                // This shouldn't happen because AuthInterceptor should handle it
                throw NetworkError.httpError(statusCode: 401, body: response.body)
            }
            
            if !response.isSuccessful {
                throw NetworkError.httpError(statusCode: response.statusCode, body: response.body)
            }
            
            // Decode manually
            guard let data = response.body else {
                throw NetworkError.noData
            }
            
            _ = try JSONDecoder().decode(Character.self, from: data)
            
            // Success
            requests[index].updateStatus(
                .success,
                message: "Request #\(requestNumber) succeeded! ✓"
            )
            
        } catch {
            // Failure
            requests[index].updateStatus(
                .failed,
                message: "Request #\(requestNumber) failed: \(error.localizedDescription)"
            )
        }
    }
    
    @MainActor
    private func reset() {
        requests = []
        tokenRefreshLog = []
        currentToken = nil
        totalRefreshes = 0
        
        Task {
            await authService.reset()
        }
    }
    
    @MainActor
    private func addLog(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        tokenRefreshLog.append("[\(timestamp)] \(message)")
        print(message)
    }
}

// MARK: - Fake 401 Interceptor

/// Interceptor that simulates 401 responses when the token in the request is invalid
/// This runs AFTER AuthInterceptor, so it can check the actual Authorization header
private struct Fake401Interceptor: Interceptor {
    
    func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        let request = chain.request
        
        // Check if request has the Authorization header (added by AuthInterceptor)
        guard let authHeader = request.headers["Authorization"] else {
            // No auth header at all - this means tokenStore was empty
            // Return 401 to trigger AuthInterceptor's refresh logic
            print("🚫 Fake401Interceptor: No Authorization header, returning 401")
            return Response(
                request: request,
                statusCode: 401,
                headers: ["WWW-Authenticate": "Bearer realm=\"demo\""],
                body: Data("{\"error\": \"Unauthorized\", \"message\": \"No authorization header\"}".utf8)
            )
        }
        
        // Extract token from "Bearer <token>"
        let token = authHeader.replacingOccurrences(of: "Bearer ", with: "")
        
        // Check if this is a real/valid token (starts with "token_")
        // Our FakeAuthService generates tokens like "token_1_abc123"
        if !token.hasPrefix("token_") {
            // This is a fake/invalid token - simulate 401
            print("🚫 Fake401Interceptor: Invalid token '\(token)', returning 401")
            return Response(
                request: request,
                statusCode: 401,
                headers: ["WWW-Authenticate": "Bearer realm=\"demo\""],
                body: Data("{\"error\": \"Unauthorized\", \"message\": \"Invalid token\"}".utf8)
            )
        }
        
        // Valid token, proceed to real API
        print("✅ Fake401Interceptor: Valid token, proceeding to API")
        return try await chain.proceed(request)
    }
}
