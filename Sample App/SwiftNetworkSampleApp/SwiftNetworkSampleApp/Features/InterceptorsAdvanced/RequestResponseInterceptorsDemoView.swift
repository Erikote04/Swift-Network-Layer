//
//  RequestResponseInterceptorsDemoView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI

struct RequestResponseInterceptorsDemoView: View {
    @State private var viewModel = RequestResponseInterceptorsDemoViewModel()

    var body: some View {
        List {
            controlsSection
            resultSection
            headersSection
        }
        .navigationTitle("Req/Res Interceptors")
    }

    private var controlsSection: some View {
        Section("Request + Response") {
            Text("Adds a request ID header and blocks error status codes in a response interceptor.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Toggle("Use failing endpoint", isOn: $viewModel.useFailureEndpoint)

            Button("Run Interceptor Demo") {
                Task { await viewModel.runDemo() }
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        Section("Result") {
            switch viewModel.state {
            case .idle:
                Text("No request yet")
                    .foregroundStyle(.secondary)
            case .loading:
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Requesting...")
                }
            case .success(let body):
                VStack(alignment: .leading, spacing: 8) {
                    Text("Request ID: \(viewModel.requestId)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(body)
                        .font(.footnote)
                        .textSelection(.enabled)
                }
            case .failed(let message):
                VStack(alignment: .leading, spacing: 8) {
                    Text("Request blocked")
                        .font(.headline)
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var headersSection: some View {
        Section("Response Headers") {
            if viewModel.responseHeaders.isEmpty {
                Text("No headers yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.responseHeaders.keys.sorted(), id: \.self) { key in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(key)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.responseHeaders[key] ?? "")
                            .font(.footnote)
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RequestResponseInterceptorsDemoView()
    }
}
