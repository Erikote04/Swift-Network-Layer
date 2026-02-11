//
//  AppleSignInView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/3/26.
//

import AuthenticationServices
import SwiftUI

struct AppleSignInView: View {
    @State private var viewModel = AppleSignInViewModel()

    var body: some View {
        List {
            Section("Status") {
                Text(viewModel.status)
                    .font(.footnote)
                    .textSelection(.enabled)
                Text(viewModel.keychainValue)
                    .font(.footnote)
                    .textSelection(.enabled)
            }

            Section("Actions") {
                if viewModel.hasStoredToken {
                    Button("Re-authenticate with Apple") {
                        Task { await viewModel.signIn() }
                    }
                } else {
                    AppleSignInButton {
                        Task { await viewModel.signIn() }
                    }
                    .frame(height: 44)
                }

                Button("Sign out") {
                    Task { await viewModel.signOut() }
                }
                .foregroundStyle(.red)
            }

            Section("Notes") {
                Text("If a token is cached, you can keep using it for your own APIs without signing in again. Re-authenticate only when you need a fresh identity token.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Best practice: exchange the Apple identity token with your backend and store your own session token.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Apple Sign-In")
        .task {
            await viewModel.loadStatus()
        }
    }
}

private struct AppleSignInButton: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTap), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    final class Coordinator: NSObject {
        private let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func didTap() {
            action()
        }
    }
}

#Preview {
    NavigationStack {
        AppleSignInView()
    }
}
