//
//  RetryDemoView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI
import SwiftNetwork

struct RetryDemoView: View {
    @State private var viewModel = RetryDemoViewModel()

    var body: some View {
        List {
            infoSection
            resultSection
        }
        .navigationTitle("Retry")
        .task {
            await viewModel.load()
        }
    }

    private var infoSection: some View {
        Section {
            Text("Uses RetryInterceptor to retry a failing request.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Run Request") {
                Task { await viewModel.load() }
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        Section("Response") {
            switch viewModel.state {
            case .idle, .loading:
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
                Task { await viewModel.load() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        RetryDemoView()
    }
}
