//
//  RetryInterceptor.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// An interceptor that retries failed requests.
///
/// `RetryInterceptor` retries requests when certain recoverable
/// network errors occur, up to a configurable maximum number of attempts.
///
/// When a metrics collector is provided, retry attempts are recorded
/// for observability and analysis.
public struct RetryInterceptor: Interceptor {

    private let maxRetries: Int
    private let delay: TimeInterval
    private let metrics: NetworkMetrics?

    /// Creates a new retry interceptor.
    ///
    /// - Parameters:
    ///   - maxRetries: The maximum number of retry attempts.
    ///   - delay: The delay between retry attempts.
    ///   - metrics: Optional metrics collector for recording retry attempts.
    public init(
        maxRetries: Int = 3,
        delay: TimeInterval = 0.5,
        metrics: NetworkMetrics? = nil
    ) {
        self.maxRetries = maxRetries
        self.delay = delay
        self.metrics = metrics
    }

    /// Intercepts a request and retries it if a retryable error occurs.
    ///
    /// - Parameter chain: The interceptor chain.
    /// - Returns: The resulting `Response`.
    /// - Throws: The final error if retries are exhausted or not retryable.
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

                // Record retry attempt
                if let metrics = metrics {
                    let retryEvent = RetryMetricEvent(
                        method: chain.request.method,
                        url: chain.request.url,
                        attemptNumber: attempt,
                        reason: errorReason(for: error),
                        retryTime: Date()
                    )
                    await metrics.recordRetry(retryEvent)
                }

                try await Task.sleep(for: .seconds(delay))
            }
        }
    }

    /// Determines whether a given error should trigger a retry.
    ///
    /// - Parameter error: The encountered network error.
    /// - Returns: `true` if the request should be retried.
    private func shouldRetry(for error: NetworkError) -> Bool {
        switch error {
        case .transportError: return true
        case .cancelled: return false
        default: return false
        }
    }
    
    /// Returns a human-readable reason for the retry.
    ///
    /// - Parameter error: The network error.
    /// - Returns: A string describing the retry reason.
    private func errorReason(for error: NetworkError) -> String {
        switch error {
        case .transportError(let underlyingError):
            return "Transport error: \(underlyingError.localizedDescription)"
        case .invalidResponse:
            return "Invalid response"
        case .cancelled:
            return "Request cancelled"
        case .noData:
            return "No data received"
        case .decodingError(let underlyingError):
            return "Decoding error: \(underlyingError.localizedDescription)"
        case .httpError(let statusCode, _):
            return "HTTP error: \(statusCode)"
        }
    }
}
