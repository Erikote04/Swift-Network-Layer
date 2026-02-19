//
//  MetricsDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class MetricsDemoViewModel {
    enum State {
        case idle
        case loading
        case loaded(AggregateMetrics.Snapshot)
        case failed(String)
    }

    var state: State = .idle

    private let metrics = AggregateMetrics()

    func runSampleRequests() async {
        if case .loading = state { return }
        state = .loading

        await metrics.reset()

        let interceptor = MetricsInterceptor(metrics: metrics)
        let retry = RetryInterceptor(maxRetries: 1, delay: 0.2)

        let config = NetworkClientConfiguration(
            baseURL: URL(string: "https://api.github.com")!,
            defaultHeaders: ["Accept": "application/vnd.github+json"],
            timeout: 20,
            interceptors: [interceptor, retry]
        )

        let client = NetworkClient(configuration: config)

        do {
            let request1 = Request(method: .get, url: URL(string: "/orgs/apple")!)
            let request2 = Request(method: .get, url: URL(string: "/orgs/apple/repos")!)

            async let response1 = client.makeCall(request1).execute()
            async let response2 = client.makeCall(request2).execute()
            _ = try await (response1, response2)

            let snapshot = await metrics.snapshot()
            state = .loaded(snapshot)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
