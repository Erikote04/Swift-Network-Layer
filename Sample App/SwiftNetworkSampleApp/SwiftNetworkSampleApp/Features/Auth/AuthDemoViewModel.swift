//
//  AuthDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class AuthDemoViewModel {
    enum State {
        case idle
        case loading
        case loaded(String)
        case failed(String)
    }

    var state: State = .idle
    var tokenInput: String = ""
    var oauthStatus: String = "Not signed in"
    var refreshStatus: String = "Idle"
    var refreshCount: Int = 0
    var googleClientId: String = ""
    var googleClientSecret: String = ""
    var googleRedirectURI: String = ""
    var googleScopes: String = "profile email"
    var seedAccessToken: String = ""
    var seedRefreshToken: String = ""
    var seedExpiresInSeconds: String = "0"

    private let tokenStore: KeychainTokenStore
    private let oauthTokenStore: KeychainTokenStore
    private let authManager: AuthManager
    private let refreshCounter = RefreshCounter()

    init() {
        tokenStore = KeychainTokenStore(service: "com.erikote04.swiftnetwork.sample")
        oauthTokenStore = KeychainTokenStore(service: "com.erikote04.swiftnetwork.sample.oauth")
        authManager = AuthManager(tokenStore: oauthTokenStore)
        googleRedirectURI = "com.erikote04.swiftnetwork.sample:/oauth"
    }

    func loadToken() async {
        tokenInput = await tokenStore.currentToken() ?? ""
    }

    func saveToken() async {
        await tokenStore.updateToken(tokenInput)
    }

    func clearToken() async {
        await tokenStore.updateToken("")
        tokenInput = ""
    }

    func fetchProfile() async {
        if case .loading = state { return }
        state = .loading

        let authInterceptor = AuthInterceptor(tokenStore: tokenStore)
        let config = NetworkClientConfiguration(
            baseURL: URL(string: "https://api.github.com")!,
            defaultHeaders: [
                "Accept": "application/vnd.github+json"
            ],
            timeout: 20,
            interceptors: [authInterceptor]
        )

        let client = NetworkClient(configuration: config)
        let request = Request(method: .get, url: URL(string: "/user")!, cachePolicy: .ignoreCache)

        do {
            let response = try await client.newCall(request).execute()
            let body = response.body.flatMap { String(data: $0, encoding: .utf8) } ?? "No body"
            state = .loaded(body)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func signInWithApple() async {
        oauthStatus = "Signing in with Apple..."
        do {
            let provider = AppleAuthProvider()
            let credentials = try await authManager.login(provider: provider)
            oauthStatus = formatAuthStatus(credentials: credentials)
        } catch {
            oauthStatus = "Apple sign-in failed: \(error.localizedDescription)"
        }
    }

    func signInWithGoogle() async {
        oauthStatus = "Signing in with Google..."
        do {
            let scopes = googleScopes
                .split(separator: " ")
                .map { String($0) }
                .filter { !$0.isEmpty }
            let provider = GoogleAuthProvider(
                clientId: googleClientId,
                redirectURI: googleRedirectURI,
                scopes: scopes.isEmpty ? ["profile", "email"] : scopes
            )
            let credentials = try await authManager.login(provider: provider)
            oauthStatus = formatAuthStatus(credentials: credentials)
            configureGoogleRefreshProvider()
        } catch {
            oauthStatus = "Google sign-in failed: \(error.localizedDescription)"
        }
    }

    func configureGoogleRefreshProvider() {
        guard !googleClientId.isEmpty else {
            refreshStatus = "Missing Google client ID"
            return
        }

        let clientId = googleClientId
        let clientSecret = googleClientSecret.isEmpty ? nil : googleClientSecret
        let service = GoogleTokenRefreshService(clientId: clientId, clientSecret: clientSecret)

        authManager.setRefreshProvider { [refreshCounter] refreshToken in
            await refreshCounter.increment()
            let response = try await service.refresh(refreshToken: refreshToken)
            return AuthCredentials(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken ?? refreshToken,
                expiresIn: TimeInterval(response.expiresIn),
                provider: .google
            )
        }

        refreshStatus = "Refresh provider configured"
    }

    func seedExpiredCredentials() async {
        guard !seedAccessToken.isEmpty, !seedRefreshToken.isEmpty else {
            refreshStatus = "Provide access + refresh tokens to seed"
            return
        }

        let expiresIn = TimeInterval(seedExpiresInSeconds) ?? 0
        let credentials = AuthCredentials(
            accessToken: seedAccessToken,
            refreshToken: seedRefreshToken,
            expiresIn: expiresIn,
            provider: .google
        )

        let provider = StaticAuthProvider(credentials: credentials)
        do {
            let newCredentials = try await authManager.login(provider: provider)
            oauthStatus = formatAuthStatus(credentials: newCredentials)
            refreshStatus = "Seeded credentials"
        } catch {
            refreshStatus = "Failed seeding credentials: \(error.localizedDescription)"
        }
    }

    func runConcurrentRefreshDemo() async {
        refreshStatus = "Running refresh demo..."
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
            refreshStatus = "Completed. Refreshes: \(refreshCount)"
        } catch {
            refreshCount = await refreshCounter.value()
            refreshStatus = "Refresh demo failed: \(error.localizedDescription)"
        }
    }

    func logoutOAuth() async {
        await authManager.logout()
        oauthStatus = "Signed out"
    }

    private func formatAuthStatus(credentials: AuthCredentials) -> String {
        let expiresIn = credentials.expiration?.remainingTime ?? 0
        return "Provider: \(credentials.provider) | Expires in: \(Int(expiresIn))s"
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
