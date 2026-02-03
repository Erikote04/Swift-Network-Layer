//
//  RepoListView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI
import SwiftNetwork

struct RepoListView: View {
    @State private var viewModel: RepoListViewModel

    init(client: NetworkClient) {
        _viewModel = State(initialValue: RepoListViewModel(client: client))
    }

    var body: some View {
        List {
            content
        }
        .navigationTitle("Apple Repos")
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
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

    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Loading repositories...")
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Something went wrong")
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
        RepoListView(client: NetworkClient())
    }
}
