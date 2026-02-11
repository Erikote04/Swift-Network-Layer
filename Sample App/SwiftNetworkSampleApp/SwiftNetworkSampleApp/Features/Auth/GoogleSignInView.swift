//
//  GoogleSignInView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/3/26.
//

import SwiftUI

struct GoogleSignInView: View {
    @State private var viewModel = GoogleSignInViewModel()

    var body: some View {
        List {
            Section("OAuth Setup") {
                TextField("Client ID", text: $viewModel.clientId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Client Secret (optional)", text: $viewModel.clientSecret)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Redirect URI", text: $viewModel.redirectURI)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Scopes (space-separated)", text: $viewModel.scopes)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Status") {
                Text(viewModel.status)
                    .font(.footnote)
                    .textSelection(.enabled)
            }

            Section("Actions") {
                Button("Sign in with Google") {
                    Task { await viewModel.signIn() }
                }

                Button("Sign out") {
                    Task { await viewModel.signOut() }
                }
                .foregroundStyle(.red)
            }

            Section("Notes") {
                Text("Make sure the URL scheme matches your reversed client ID.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Google Sign-In")
    }
}

#Preview {
    NavigationStack {
        GoogleSignInView()
    }
}
