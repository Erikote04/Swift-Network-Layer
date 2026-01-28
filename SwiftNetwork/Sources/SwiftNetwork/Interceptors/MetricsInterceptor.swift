//
//  MetricsInterceptor.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork on 21/1/26.
//

import Foundation

/// An interceptor that records network metrics for all requests.
///
/// This interceptor captures timing information, response status,
/// and error details, forwarding them to a configured metrics collector.
///
/// ## Usage
///
/// ```swift
/// let metrics = ConsoleMetrics()
/// let interceptor = MetricsInterceptor(metrics: metrics)
///
/// let config = NetworkClientConfiguration(
///     interceptors: [interceptor]
/// )
/// ```
public final class MetricsInterceptor: Interceptor {
    
    private let metrics: NetworkMetrics
    private let tags: [String: String]
    
    /// Creates a new metrics interceptor.
    ///
    /// - Parameters:
    ///   - metrics: The metrics collector.
    ///   - tags: Default tags applied to all events.
    public init(
        metrics: NetworkMetrics,
        tags: [String: String] = [:]
    ) {
        self.metrics = metrics
        self.tags = tags
    }
    
    public func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        let request = chain.request
        let startTime = Date()
        
        do {
            let response = try await chain.proceed(request)
            let endTime = Date()
            
            let event = RequestMetricEvent(
                method: request.method,
                url: request.url,
                statusCode: response.statusCode,
                startTime: startTime,
                endTime: endTime,
                requestBodySize: request.body?.estimatedSize,
                responseBodySize: response.body?.count ?? 0,
                tags: tags
            )
            
            await metrics.recordRequest(event)
            
            return response
        } catch {
            let errorTime = Date()
            let networkError = error as? NetworkError ?? .transportError(error)
            
            let errorEvent = ErrorMetricEvent(
                method: request.method,
                url: request.url,
                error: networkError,
                startTime: startTime,
                errorTime: errorTime,
                tags: tags
            )
            
            await metrics.recordError(errorEvent)
            
            throw error
        }
    }
}

private extension RequestBody {
    var estimatedSize: Int? {
        switch self {
        case .data(let data, _):
            return data.count
        case .json(let encodable, let encoder):
            return (try? encoder.encode(AnyEncodableWrapper(encodable)))?.count
        case .form(let params):
            return params.map { "\($0.key)=\($0.value)" }.joined(separator: "&").utf8.count
        case .multipart(let parts):
            return parts.reduce(0) { $0 + $1.data.count }
        }
    }
}
