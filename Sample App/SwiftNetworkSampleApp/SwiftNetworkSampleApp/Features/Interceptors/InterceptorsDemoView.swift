//
//  InterceptorsDemoView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI
import SwiftNetwork

struct InterceptorsDemoView: View {
    @State private var viewModel: InterceptorsDemoViewModel

    init(client: NetworkClient) {
        _viewModel = State(initialValue: InterceptorsDemoViewModel(client: client))
    }

    var body: some View {
        List {
            configSection
            resultSection
        }
        .navigationTitle("Interceptors")
        .task {
            await viewModel.load()
        }
    }

    private var configSection: some View {
        Section("Conditional Header") {
            Toggle("Inject X-Demo-Header", isOn: $viewModel.shouldInjectHeader)
            Text("Uses ConditionalInterceptor to inject a header when enabled.")
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
        InterceptorsDemoView(client: NetworkClient())
    }
}
