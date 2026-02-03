//
//  RequestBuilderDemoView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI
import SwiftNetwork

struct RequestBuilderDemoView: View {
    @State private var viewModel: RequestBuilderDemoViewModel

    init(client: NetworkClient) {
        _viewModel = State(initialValue: RequestBuilderDemoViewModel(client: client))
    }

    var body: some View {
        List {
            infoSection
            contentSection
        }
        .navigationTitle("Request Builder")
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private var infoSection: some View {
        Section {
            Text("Uses RequestBuilder to configure query items, headers, cache policy, and timeout.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var contentSection: some View {
        Section("Top Swift Repos") {
            switch viewModel.state {
            case .idle, .loading:
                loadingView
            case .loaded(let repos):
                ForEach(repos) { repo in
                    RepoRow(repo: repo)
                }
            case .failed(let message):
                errorView(message: message)
            }
        }
    }

    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Loading results...")
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search failed")
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
        RequestBuilderDemoView(client: NetworkClient())
    }
}
