//
//  CacheDemoView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI
import SwiftNetwork

struct CacheDemoView: View {
    @State private var viewModel = CacheDemoViewModel()

    var body: some View {
        List {
            configSection
            resultSection
        }
        .navigationTitle("Caching")
        .task {
            await viewModel.load()
        }
    }

    private var configSection: some View {
        Section("Configuration") {
            Picker("Cache", selection: $viewModel.selectedCache) {
                ForEach(CacheDemoViewModel.CacheType.allCases) { cache in
                    Text(cache.rawValue).tag(cache)
                }
            }

            Picker("Policy", selection: $viewModel.policy) {
                Text("Use Cache").tag(CachePolicy.useCache)
                Text("Ignore Cache").tag(CachePolicy.ignoreCache)
                Text("Revalidate").tag(CachePolicy.revalidate)
                Text("Respect Headers").tag(CachePolicy.respectHeaders)
            }

            HStack {
                Button("Load") {
                    Task { await viewModel.load() }
                }
                Spacer()
                Button("Clear Cache") {
                    Task { await viewModel.clearCache() }
                }
                .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        Section("Result") {
            switch viewModel.state {
            case .idle, .loading:
                loadingView
            case .loaded(let repos, let cacheResult):
                cacheResultView(cacheResult)
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
            Text("Loading...")
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func cacheResultView(_ result: String) -> some View {
        HStack {
            Text("Cache Result")
            Spacer()
            Text(result)
                .foregroundStyle(.secondary)
        }
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
        CacheDemoView()
    }
}
