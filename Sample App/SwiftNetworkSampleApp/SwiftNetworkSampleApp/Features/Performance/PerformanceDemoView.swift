//
//  PerformanceDemoView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI
import SwiftNetwork

struct PerformanceDemoView: View {
    @State private var viewModel = PerformanceDemoViewModel()

    var body: some View {
        List {
            dedupSection
            prioritySection
        }
        .navigationTitle("Performance")
    }

    private var dedupSection: some View {
        Section("Request Deduplication") {
            Text("Runs two identical requests concurrently. With deduplication enabled, SwiftNetwork shares one in-flight request.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Run Deduplication Demo") {
                Task { await viewModel.runDeduplicationDemo() }
            }
            .disabled(viewModel.isDedupRunning)

            Text(viewModel.dedupSummary)
                .font(.footnote)
                .foregroundStyle(.secondary)

            logList(viewModel.dedupLogs)
        }
    }

    private var prioritySection: some View {
        Section("Request Priority") {
            Text("Uses `RequestPriority` to influence scheduling for concurrent requests.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Run Priority Demo") {
                Task { await viewModel.runPriorityDemo() }
            }
            .disabled(viewModel.isPriorityRunning)

            Text(viewModel.prioritySummary)
                .font(.footnote)
                .foregroundStyle(.secondary)

            logList(viewModel.priorityLogs)
        }
    }

    @ViewBuilder
    private func logList(_ logs: [PerformanceDemoViewModel.LogEntry]) -> some View {
        if logs.isEmpty {
            Text("No logs yet")
                .foregroundStyle(.secondary)
        } else {
            ForEach(logs) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.title)
                            .font(.subheadline)
                        Spacer()
                        Text(entry.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(entry.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PerformanceDemoView()
    }
}
