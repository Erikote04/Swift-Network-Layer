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

    private let authManager: AuthManager

    init() {
        let tokenStore = KeychainTokenStore(service: "com.erikote04.swiftnetwork.sample.apple")
        authManager = AuthManager(tokenStore: tokenStore)
    }

    func signIn() async {
        status = "Signing in with Apple..."
        do {
            let provider = AppleAuthProvider()
            let credentials = try await authManager.login(provider: provider)
            status = formatStatus(credentials)
        } catch {
            status = "Apple sign-in failed: \(error.localizedDescription)"
        }
    }

    func signOut() async {
        await authManager.logout()
        status = "Signed out"
    }

    private func formatStatus(_ credentials: AuthCredentials) -> String {
        let expiresIn = credentials.expiration?.expiresAt.timeIntervalSinceNow ?? 0
        return "Provider: \(credentials.provider) | Expires in: \(Int(expiresIn))s"
    }
}
