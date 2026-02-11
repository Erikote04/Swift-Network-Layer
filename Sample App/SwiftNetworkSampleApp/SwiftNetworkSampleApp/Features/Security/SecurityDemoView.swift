//
//  SecurityDemoView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI
import SwiftNetwork

struct SecurityDemoView: View {
    @State private var viewModel = SecurityDemoViewModel()

    var body: some View {
        List {
            pinningSection
            resultSection
            guidanceSection
        }
        .navigationTitle("Security")
    }

    private var pinningSection: some View {
        Section("Certificate Pinning") {
            Text("Toggle pinning to see how the client behaves. With placeholder pins, the pinned request fails by design.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Toggle("Enable Pinning", isOn: $viewModel.isPinningEnabled)

            Button("Run Pinning Demo") {
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
                    Text("Requesting /zen")
                }
            case .success(let status, let body):
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status: \(status)")
                        .font(.headline)
                    Text(body)
                        .font(.footnote)
                        .textSelection(.enabled)
                }
            case .failed(let message):
                VStack(alignment: .leading, spacing: 8) {
                    Text("Request failed")
                        .font(.headline)
                    Text(message)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }
        }
    }

    private var guidanceSection: some View {
        Section("How To Use In Production") {
            ForEach(viewModel.instructions, id: \.self) { item in
                Text(item)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SecurityDemoView()
    }
}
