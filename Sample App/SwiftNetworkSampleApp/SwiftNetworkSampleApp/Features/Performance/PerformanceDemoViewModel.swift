//
//  PerformanceDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class PerformanceDemoViewModel {
    struct LogEntry: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let detail: String
        let timestamp: Date
    }

    var dedupSummary: String = "No run yet"
    var prioritySummary: String = "No run yet"
    var dedupLogs: [LogEntry] = []
    var priorityLogs: [LogEntry] = []
    var isDedupRunning = false
    var isPriorityRunning = false

    private let baseURL = URL(string: "https://httpbin.org")!

    func runDeduplicationDemo() async {
        guard !isDedupRunning else { return }
        isDedupRunning = true
        dedupLogs.removeAll()
        dedupSummary = "Running two identical requests..."

        let config = NetworkClientConfiguration(
            baseURL: baseURL,
            enableDeduplication: true
        )
        let client = NetworkClient(configuration: config)
        let request = Request(method: .get, url: URL(string: "/delay/2")!, cachePolicy: .ignoreCache)

        do {
            let started = Date()
            async let first = timed { try await client.makeCall(request).execute() }
            async let second = timed { try await client.makeCall(request).execute() }

            let (firstResponse, firstDuration) = try await first
            let (secondResponse, secondDuration) = try await second
            let elapsed = Date().timeIntervalSince(started)

            dedupLogs.append(LogEntry(
                title: "Call A",
                detail: "Status \(firstResponse.statusCode), \(format(firstDuration))",
                timestamp: Date()
            ))
            dedupLogs.append(LogEntry(
                title: "Call B",
                detail: "Status \(secondResponse.statusCode), \(format(secondDuration))",
                timestamp: Date()
            ))

            dedupSummary = "Completed both in \(format(elapsed)). Deduplication enabled."
        } catch {
            dedupSummary = "Failed: \(error.localizedDescription)"
            dedupLogs.append(LogEntry(
                title: "Error",
                detail: error.localizedDescription,
                timestamp: Date()
            ))
        }

        isDedupRunning = false
    }

    func runPriorityDemo() async {
        guard !isPriorityRunning else { return }
        isPriorityRunning = true
        priorityLogs.removeAll()
        prioritySummary = "Running priority requests..."

        let config = NetworkClientConfiguration(baseURL: baseURL)
        let client = NetworkClient(configuration: config)

        let highRequest = Request(
            method: .get,
            url: URL(string: "/delay/1")!,
            cachePolicy: .ignoreCache,
            priority: .high
        )
        let backgroundRequest = Request(
            method: .get,
            url: URL(string: "/delay/1")!,
            cachePolicy: .ignoreCache,
            priority: .background
        )

        do {
            let started = Date()
            async let high = timed { try await client.makeCall(highRequest).execute() }
            async let background = timed { try await client.makeCall(backgroundRequest).execute() }

            let (highResponse, highDuration) = try await high
            let (backgroundResponse, backgroundDuration) = try await background
            let elapsed = Date().timeIntervalSince(started)

            priorityLogs.append(LogEntry(
                title: "High Priority",
                detail: "Status \(highResponse.statusCode), \(format(highDuration))",
                timestamp: Date()
            ))
            priorityLogs.append(LogEntry(
                title: "Background Priority",
                detail: "Status \(backgroundResponse.statusCode), \(format(backgroundDuration))",
                timestamp: Date()
            ))

            prioritySummary = "Completed both in \(format(elapsed)). Priority influences scheduling."
        } catch {
            prioritySummary = "Failed: \(error.localizedDescription)"
            priorityLogs.append(LogEntry(
                title: "Error",
                detail: error.localizedDescription,
                timestamp: Date()
            ))
        }

        isPriorityRunning = false
    }

    private func timed<T>(_ operation: @escaping @Sendable () async throws -> T) async throws -> (T, TimeInterval) {
        let start = Date()
        let value = try await operation()
        let duration = Date().timeIntervalSince(start)
        return (value, duration)
    }

    private func format(_ duration: TimeInterval) -> String {
        String(format: "%.2fs", duration)
    }
}
