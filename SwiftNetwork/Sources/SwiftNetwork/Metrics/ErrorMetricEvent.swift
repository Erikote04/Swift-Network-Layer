//
//  ErrorMetricEvent.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 21/1/26.
//

import Foundation

/// Represents metrics for a failed network request.
///
/// This event captures error information and timing for failed requests.
public struct ErrorMetricEvent: Sendable {
    
    /// The HTTP method used for the request.
    public let method: HTTPMethod
    
    /// The URL of the request.
    public let url: URL
    
    /// The error that occurred.
    public let error: NetworkError
    
    /// The time when the request started.
    public let startTime: Date
    
    /// The time when the error occurred.
    public let errorTime: Date
    
    /// The duration until the error occurred, in seconds.
    public var duration: TimeInterval {
        errorTime.timeIntervalSince(startTime)
    }
    
    /// Custom tags for categorizing metrics.
    public let tags: [String: String]
    
    /// Creates a new error metric event.
    ///
    /// - Parameters:
    ///   - method: The HTTP method.
    ///   - url: The request URL.
    ///   - error: The network error.
    ///   - startTime: When the request started.
    ///   - errorTime: When the error occurred.
    ///   - tags: Custom tags for categorization.
    public init(
        method: HTTPMethod,
        url: URL,
        error: NetworkError,
        startTime: Date,
        errorTime: Date,
        tags: [String: String] = [:]
    ) {
        self.method = method
        self.url = url
        self.error = error
        self.startTime = startTime
        self.errorTime = errorTime
        self.tags = tags
    }
}
