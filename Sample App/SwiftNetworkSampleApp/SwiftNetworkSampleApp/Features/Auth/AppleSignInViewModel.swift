//
//  AppleSignInViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/3/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class AppleSignInViewModel {
    var status: String = "Not signed in"
    var hasStoredToken: Bool = false
    var keychainValue: String = "Keychain: (loading)"

    private let tokenStore: KeychainTokenStore
    private let authManager: AuthManager

    init() {
        tokenStore = KeychainTokenStore(service: "com.erikote04.swiftnetwork.sample.apple")
        authManager = AuthManager(tokenStore: tokenStore)
    }

    func loadStatus() async {
        let token = await tokenStore.currentToken() ?? ""
        keychainValue = token.isEmpty ? "Keychain: (empty)" : "Keychain: \(token)"
        if !token.isEmpty {
            hasStoredToken = true
            status = "Token stored in Keychain (sign-in not required for API calls)"
        } else {
            hasStoredToken = false
            status = "Not signed in"
        }
    }

    func signIn() async {
        status = "Signing in with Apple..."
        do {
            let provider = AppleAuthProvider()
            let credentials = try await authManager.login(provider: provider)
            hasStoredToken = true
            status = formatStatus(credentials)
            await loadStatus()
        } catch {
            hasStoredToken = false
            status = "Apple sign-in failed: \(error.localizedDescription)"
            await loadStatus()
        }
    }

    func signOut() async {
        await authManager.logout()
        hasStoredToken = false
        status = "Signed out"
        await loadStatus()
    }

    private func formatStatus(_ credentials: AuthCredentials) -> String {
        let expiresIn = credentials.expiration?.expiresAt.timeIntervalSinceNow ?? 0
        return "Provider: \(credentials.provider) | Expires in: \(Int(expiresIn))s"
    }
}
