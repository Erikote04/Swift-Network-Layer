//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public struct RetryInterceptor: Interceptor {
    
    private let maxRetries: Int
    private let delay: TimeInterval

    public init(maxRetries: Int = 3, delay: TimeInterval = 0.5) {
        self.maxRetries = maxRetries
        self.delay = delay
    }

    public func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        var attempt = 0

        while true {
            do {
                return try await chain.proceed(chain.request)
            } catch let error as NetworkError {
                attempt += 1

                guard attempt <= maxRetries,
                      shouldRetry(for: error) else {
                    throw error
                }

                try await Task.sleep(for: .seconds(delay))
            }
        }
    }

    private func shouldRetry(for error: NetworkError) -> Bool {
        switch error {
        case .transportError: return true
        case .cancelled: return false
        default: return false
        }
    }
}
