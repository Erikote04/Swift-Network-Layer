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
