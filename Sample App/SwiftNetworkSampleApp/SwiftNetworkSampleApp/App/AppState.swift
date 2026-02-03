//
//  AppState.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI
import SwiftNetwork

@MainActor
@Observable
final class AppState {
    let client: NetworkClient

    init() {
        let config = NetworkClientConfiguration(
            baseURL: URL(string: "https://api.github.com")!,
            defaultHeaders: [
                "Accept": "application/vnd.github+json"
            ],
            timeout: 30,
            interceptors: [
                LoggingInterceptor(level: .basic),
                RetryInterceptor(maxRetries: 2, delay: 0.4)
            ]
        )
        self.client = NetworkClient(configuration: config)
    }
}
