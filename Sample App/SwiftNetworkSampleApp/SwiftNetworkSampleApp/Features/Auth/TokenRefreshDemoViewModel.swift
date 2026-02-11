//
//  TokenRefreshDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/3/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class TokenRefreshDemoViewModel {
    var status: String = "Idle"
    var refreshCount: Int = 0
    var googleClientId: String = ""
    var googleClientSecret: String = ""
    var accessToken: String = ""
    var refreshToken: String = ""
    var expiresInSeconds: String = "0"

    private let authManager: AuthManager
    private let refreshCounter = RefreshCounter()

    init() {
        let tokenStore = KeychainTokenStore(service: "com.erikote04.swiftnetwork.sample.refresh")
        authManager = AuthManager(tokenStore: tokenStore)
    }

    func configureRefreshProvider() async {
        guard !googleClientId.isEmpty else {
            status = "Missing Google client ID"
            return
        }

        let clientId = googleClientId
        let clientSecret = googleClientSecret.isEmpty ? nil : googleClientSecret
        let service = GoogleTokenRefreshService(clientId: clientId, clientSecret: clientSecret)

        await authManager.setRefreshProvider { [refreshCounter] refreshToken in
            await refreshCounter.increment()
            let response = try await service.refresh(refreshToken: refreshToken)
            return AuthCredentials(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken ?? refreshToken,
                expiresIn: TimeInterval(response.expiresIn),
                provider: .google
            )
        }

        status = "Refresh provider configured"
    }

    func seedExpiredCredentials() async {
        guard !accessToken.isEmpty, !refreshToken.isEmpty else {
            status = "Provide access + refresh tokens to seed"
            return
        }

        let expiresIn = TimeInterval(expiresInSeconds) ?? 0
        let credentials = AuthCredentials(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn,
            provider: .google
        )

        let provider = StaticAuthProvider(credentials: credentials)
        do {
            _ = try await authManager.login(provider: provider)
            status = "Seeded credentials"
        } catch {
            status = "Failed seeding credentials: \(error.localizedDescription)"
        }
    }

    func runConcurrentRefreshDemo() async {
        status = "Running refresh demo..."
        await refreshCounter.reset()

        let config = NetworkClientConfiguration(
            baseURL: URL(string: "https://httpbin.org")!,
            defaultHeaders: ["Accept": "application/json"],
            timeout: 20,
            interceptors: [AuthInterceptor(authManager: authManager)]
        )
        let client = NetworkClient(configuration: config)
        let request = Request(method: .get, url: URL(string: "/get")!, cachePolicy: .ignoreCache)

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<5 {
                    group.addTask {
                        _ = try await client.newCall(request).execute()
                    }
                }
                try await group.waitForAll()
            }

            refreshCount = await refreshCounter.value()
            status = "Completed. Refreshes: \(refreshCount)"
        } catch {
            refreshCount = await refreshCounter.value()
            status = "Refresh demo failed: \(error.localizedDescription)"
        }
    }
}

private actor RefreshCounter {
    private var count: Int = 0

    func increment() {
        count += 1
    }

    func reset() {
        count = 0
    }

    func value() -> Int {
        count
    }
}

private struct StaticAuthProvider: AuthProvider {
    let credentials: AuthCredentials

    func login() async throws -> AuthCredentials {
        credentials
    }
}
