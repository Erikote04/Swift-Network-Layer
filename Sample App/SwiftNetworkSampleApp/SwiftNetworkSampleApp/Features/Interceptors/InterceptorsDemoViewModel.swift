//
//  InterceptorsDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class InterceptorsDemoViewModel {
    enum State {
        case idle
        case loading
        case loaded(String)
        case failed(String)
    }

    var state: State = .idle
    var shouldInjectHeader: Bool = true

    private let baseURL = URL(string: "https://httpbin.org")!

    func load() async {
        if case .loading = state { return }
        state = .loading

        let request = Request(
            method: .get,
            url: URL(string: "/headers")!,
            cachePolicy: .ignoreCache
        )

        do {
            let client = configuredClient()
            let response = try await client.newCall(request).execute()
            let bodyText = response.body.flatMap { String(data: $0, encoding: .utf8) } ?? "No body"
            state = .loaded(bodyText)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func configuredClient() -> NetworkClient {
        let injectHeader = HeaderInjectionInterceptor(name: "X-Demo-Header", value: "swift-network")
        let conditional = ConditionalInterceptor(
            interceptor: injectHeader,
            condition: .custom { [shouldInjectHeader] _ in
                shouldInjectHeader
            }
        )

        let prioritized = PrioritizedInterceptor(interceptor: conditional, priority: 10)

        let config = NetworkClientConfiguration(
            baseURL: baseURL,
            defaultHeaders: ["Accept": "application/json"],
            timeout: 20,
            interceptors: [prioritized]
        )

        return NetworkClient(configuration: config)
    }
}
