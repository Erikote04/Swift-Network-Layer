//
//  StreamingDemoView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI
import SwiftNetwork

struct StreamingDemoView: View {
    @State private var viewModel: StreamingDemoViewModel

    init(client: NetworkClient) {
        _viewModel = State(initialValue: StreamingDemoViewModel(client: client))
    }

    var body: some View {
        List {
            infoSection
            resultSection
        }
        .navigationTitle("Streaming")
    }

    private var infoSection: some View {
        Section {
            Text("Streams 64 KB of data and updates chunk counts in real time.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Start Stream") {
                Task { await viewModel.startStreaming() }
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        Section("Status") {
            switch viewModel.state {
            case .idle:
                Text("Idle")
            case .streaming(let bytes, let chunks):
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bytes: \(bytes)")
                    Text("Chunks: \(chunks)")
                        .foregroundStyle(.secondary)
                }
            case .completed(let bytes, let chunks):
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completed")
                        .font(.headline)
                    Text("Total bytes: \(bytes)")
                    Text("Total chunks: \(chunks)")
                        .foregroundStyle(.secondary)
                }
            case .failed(let message):
                errorView(message: message)
            }
        }
    }

    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stream failed")
                .font(.headline)
            Text(message)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                Task { await viewModel.startStreaming() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        StreamingDemoView(client: NetworkClient())
    }
}
