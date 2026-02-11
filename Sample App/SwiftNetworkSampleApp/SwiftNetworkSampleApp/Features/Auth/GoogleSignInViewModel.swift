//
//  GoogleSignInViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/3/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class GoogleSignInViewModel {
    var status: String = "Not signed in"
    var clientId: String = ""
    var clientSecret: String = ""
    var redirectURI: String = ""
    var scopes: String = "profile email"

    private let authManager: AuthManager

    init() {
        let tokenStore = KeychainTokenStore(service: "com.erikote04.swiftnetwork.sample.google")
        authManager = AuthManager(tokenStore: tokenStore)
        redirectURI = "com.erikote04.swiftnetwork.sample:/oauth"
    }

    func signIn() async {
        status = "Signing in with Google..."
        do {
            let scopeList = scopes
                .split(separator: " ")
                .map { String($0) }
                .filter { !$0.isEmpty }
            let provider = GoogleAuthProvider(
                clientId: clientId,
                redirectURI: redirectURI,
                scopes: scopeList.isEmpty ? ["profile", "email"] : scopeList
            )
            let credentials = try await authManager.login(provider: provider)
            status = formatStatus(credentials)
        } catch {
            status = "Google sign-in failed: \(error.localizedDescription)"
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
