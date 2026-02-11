//
//  ProgressDemoView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI
import SwiftNetwork

struct ProgressDemoView: View {
    @State private var viewModel: ProgressDemoViewModel

    init(client: NetworkClient) {
        _viewModel = State(initialValue: ProgressDemoViewModel(client: client))
    }

    var body: some View {
        List {
            infoSection
            resultSection
        }
        .navigationTitle("Progress")
    }

    private var infoSection: some View {
        Section {
            Text("Uploads binary data and reports progress from the transport layer.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Start Upload") {
                Task { await viewModel.upload() }
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        Section("Status") {
            switch viewModel.state {
            case .idle:
                Text("Idle")
            case .uploading(let progress):
                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: progress)
                    Text("Progress: \(progress, format: .percent)")
                        .font(.subheadline)
                }
            case .completed(let message):
                Text(message)
            case .failed(let message):
                errorView(message: message)
            }
        }
    }

    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upload failed")
                .font(.headline)
            Text(message)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                Task { await viewModel.upload() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProgressDemoView(client: NetworkClient())
    }
}
