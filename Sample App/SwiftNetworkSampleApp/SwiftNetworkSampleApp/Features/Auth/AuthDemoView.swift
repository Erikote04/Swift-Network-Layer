//
//  AuthDemoView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI
import SwiftNetwork

struct AuthDemoView: View {
    @State private var viewModel = AuthDemoViewModel()

    var body: some View {
        List {
            tokenSection
            oauthSetupSection
            oauthActionsSection
            oauthStatusSection
            refreshSetupSection
            refreshActionsSection
            resultSection
        }
        .navigationTitle("Auth")
        .task {
            await viewModel.loadToken()
        }
    }

    private var tokenSection: some View {
        Section("GitHub Token") {
            Text("Paste a GitHub Personal Access Token to call /user.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("ghp_...", text: $viewModel.tokenInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            HStack {
                Button("Save") {
                    Task { await viewModel.saveToken() }
                }
                Spacer()
                Button("Clear") {
                    Task { await viewModel.clearToken() }
                }
                .foregroundStyle(.red)
            }

            Button("Fetch Profile") {
                Task { await viewModel.fetchProfile() }
            }
        }
    }

    private var oauthSetupSection: some View {
        Section("OAuth Setup (Google)") {
            Text("Use your Google OAuth client to get refresh tokens for the demo.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Client ID", text: $viewModel.googleClientId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Client Secret (optional)", text: $viewModel.googleClientSecret)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Redirect URI", text: $viewModel.googleRedirectURI)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Scopes (space-separated)", text: $viewModel.googleScopes)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    private var oauthActionsSection: some View {
        Section("OAuth Actions") {
            Button("Sign in with Apple") {
                Task { await viewModel.signInWithApple() }
            }

            Button("Sign in with Google") {
                Task { await viewModel.signInWithGoogle() }
            }

            Button("Sign out") {
                Task { await viewModel.logoutOAuth() }
            }
            .foregroundStyle(.red)
        }
    }

    private var oauthStatusSection: some View {
        Section("OAuth Status") {
            Text(viewModel.oauthStatus)
                .font(.footnote)
                .textSelection(.enabled)
        }
    }

    private var refreshSetupSection: some View {
        Section("Token Refresh Setup") {
            Text("Seed an expired access token to force refresh on the next requests.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Access Token", text: $viewModel.seedAccessToken)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Refresh Token", text: $viewModel.seedRefreshToken)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Expires In (seconds)", text: $viewModel.seedExpiresInSeconds)
                .keyboardType(.numberPad)
        }
    }

    private var refreshActionsSection: some View {
        Section("Token Refresh Demo") {
            Button("Configure Refresh Provider") {
                Task { await viewModel.configureGoogleRefreshProvider() }
            }

            Button("Seed Expired Credentials") {
                Task { await viewModel.seedExpiredCredentials() }
            }

            Button("Run Concurrent Refresh Demo") {
                Task { await viewModel.runConcurrentRefreshDemo() }
            }

            Text(viewModel.refreshStatus)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("Refreshes performed: \(viewModel.refreshCount)")
                .font(.footnote)
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        Section("Response") {
            switch viewModel.state {
            case .idle:
                Text("No response yet")
            case .loading:
                loadingView
            case .loaded(let body):
                Text(body)
                    .font(.footnote)
                    .textSelection(.enabled)
            case .failed(let message):
                errorView(message: message)
            }
        }
    }

    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Loading...")
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Request failed")
                .font(.headline)
            Text(message)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                Task { await viewModel.fetchProfile() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AuthDemoView()
    }
}
