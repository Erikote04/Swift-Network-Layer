//
//  RetryDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class RetryDemoViewModel {
    enum State {
        case idle
        case loading
        case loaded(String)
        case failed(String)
    }

    var state: State = .idle
    var retryCount: Int = 0

    private let baseURL = URL(string: "https://httpstat.us")!
    private let metrics = RetryMetricsCollector()

    func load() async {
        if case .loading = state { return }
        state = .loading

        await metrics.reset()

        let request = Request(
            method: .get,
            url: URL(string: "/503")!,
            cachePolicy: .ignoreCache
        )

        do {
            let config = NetworkClientConfiguration(
                baseURL: baseURL,
                timeout: 10,
                interceptors: [
                    RetryInterceptor(maxRetries: 2, delay: 0.2, metrics: metrics)
                ]
            )
            let client = NetworkClient(configuration: config)

            let response = try await client.newCall(request).execute()
            let bodyText = response.body.flatMap { String(data: $0, encoding: .utf8) } ?? "No body"

            retryCount = await metrics.count()
            state = .loaded("Status: \(response.statusCode)\nRetries: \(retryCount)\n\n\(bodyText)")
        } catch {
            retryCount = await metrics.count()
            state = .failed("Retries: \(retryCount)\n\n\(error.localizedDescription)")
        }
    }
}
