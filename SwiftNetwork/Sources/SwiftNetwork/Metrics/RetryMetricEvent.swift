//
//  RetryMetricEvent.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 21/1/26.
//

import Foundation

/// Represents metrics for a retry attempt.
///
/// This event tracks retry attempts for failed requests,
/// including the attempt number and reason for retry.
public struct RetryMetricEvent: Sendable {
    
    /// The HTTP method of the retried request.
    public let method: HTTPMethod
    
    /// The URL of the retried request.
    public let url: URL
    
    /// The retry attempt number (1-indexed).
    public let attemptNumber: Int
    
    /// The reason for the retry.
    public let reason: String
    
    /// The time when the retry was initiated.
    public let retryTime: Date
    
    /// Custom tags for categorizing metrics.
    public let tags: [String: String]
    
    /// Creates a new retry metric event.
    ///
    /// - Parameters:
    ///   - method: The HTTP method.
    ///   - url: The request URL.
    ///   - attemptNumber: The retry attempt number.
    ///   - reason: The reason for retry.
    ///   - retryTime: When the retry was initiated.
    ///   - tags: Custom tags for categorization.
    public init(
        method: HTTPMethod,
        url: URL,
        attemptNumber: Int,
        reason: String,
        retryTime: Date,
        tags: [String: String] = [:]
    ) {
        self.method = method
        self.url = url
        self.attemptNumber = attemptNumber
        self.reason = reason
        self.retryTime = retryTime
        self.tags = tags
    }
}
