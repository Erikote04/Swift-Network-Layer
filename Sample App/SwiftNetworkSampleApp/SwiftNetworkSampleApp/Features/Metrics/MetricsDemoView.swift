//
//  MetricsDemoView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI
import SwiftNetwork

struct MetricsDemoView: View {
    @State private var viewModel = MetricsDemoViewModel()

    var body: some View {
        List {
            infoSection
            resultSection
        }
        .navigationTitle("Metrics")
    }

    private var infoSection: some View {
        Section {
            Text("Runs two parallel requests and aggregates metrics.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Run Sample") {
                Task { await viewModel.runSampleRequests() }
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        Section("Snapshot") {
            switch viewModel.state {
            case .idle:
                Text("No data yet")
            case .loading:
                loadingView
            case .loaded(let snapshot):
                snapshotView(snapshot)
            case .failed(let message):
                errorView(message: message)
            }
        }
    }

    private var loadingView: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text("Collecting metrics...")
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func snapshotView(_ snapshot: AggregateMetrics.Snapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Requests: \(snapshot.totalRequests)")
            Text("Success rate: \(snapshot.successRate, format: .percent)")
            Text("Average duration: \(snapshot.averageDuration, format: .number.precision(.fractionLength(2))) s")
            Text("P95 duration: \(snapshot.p95Duration, format: .number.precision(.fractionLength(2))) s")
            Text("Bytes sent: \(snapshot.totalBytesSent)")
            Text("Bytes received: \(snapshot.totalBytesReceived)")
            Text("Retries: \(snapshot.totalRetries)")
            Text("Cache hit rate: \(snapshot.cacheHitRate, format: .percent)")
        }
        .font(.subheadline)
    }

    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Metrics failed")
                .font(.headline)
            Text(message)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                Task { await viewModel.runSampleRequests() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MetricsDemoView()
    }
}
