//
//  TokenRefreshDemoView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/3/26.
//

import SwiftUI

struct TokenRefreshDemoView: View {
    @State private var viewModel = TokenRefreshDemoViewModel()

    var body: some View {
        List {
            Section("Google Refresh Setup") {
                TextField("Client ID", text: $viewModel.googleClientId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Client Secret (optional)", text: $viewModel.googleClientSecret)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Seed Expired Credentials") {
                TextField("Access Token", text: $viewModel.accessToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Refresh Token", text: $viewModel.refreshToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Expires In (seconds)", text: $viewModel.expiresInSeconds)
                    .keyboardType(.numberPad)
            }

            Section("Actions") {
                Button("Configure Refresh Provider") {
                    Task { await viewModel.configureRefreshProvider() }
                }

                Button("Seed Credentials") {
                    Task { await viewModel.seedExpiredCredentials() }
                }

                Button("Run Concurrent Refresh Demo") {
                    Task { await viewModel.runConcurrentRefreshDemo() }
                }
            }

            Section("Status") {
                Text(viewModel.status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Refreshes performed: \(viewModel.refreshCount)")
                    .font(.footnote)
            }
        }
        .navigationTitle("Token Refresh")
    }
}

#Preview {
    NavigationStack {
        TokenRefreshDemoView()
    }
}
