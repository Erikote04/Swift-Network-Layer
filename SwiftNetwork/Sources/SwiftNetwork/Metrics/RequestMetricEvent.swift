//
//  RequestMetricEvent.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 21/1/26.
//

import Foundation

/// Represents metrics for a completed network request.
///
/// Event that captures timing information, response status,
/// and metadata about the request execution.
public struct RequestMetricEvent: Sendable {
    
    /// The HTTP method used for the request.
    public let method: HTTPMethod
    
    /// The URL of the request.
    public let url: URL
    
    /// The HTTP status code of the response.
    public let statusCode: Int
    
    /// The time when the request started.
    public let startTime: Date
    
    /// The time when the request completed.
    public let endTime: Date
    
    /// The total duration of the request in seconds.
    public var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    /// The size of the request body in bytes, if any.
    public let requestBodySize: Int?
    
    /// The size of the response body in bytes.
    public let responseBodySize: Int
    
    /// Custom tags for categorizing metrics.
    public let tags: [String: String]
    
    /// Creates a new request metric event.
    ///
    /// - Parameters:
    ///   - method: The HTTP method.
    ///   - url: The request URL.
    ///   - statusCode: The HTTP status code.
    ///   - startTime: When the request started.
    ///   - endTime: When the request completed.
    ///   - requestBodySize: Size of the request body in bytes.
    ///   - responseBodySize: Size of the response body in bytes.
    ///   - tags: Custom tags for categorization.
    public init(
        method: HTTPMethod,
        url: URL,
        statusCode: Int,
        startTime: Date,
        endTime: Date,
        requestBodySize: Int? = nil,
        responseBodySize: Int,
        tags: [String: String] = [:]
    ) {
        self.method = method
        self.url = url
        self.statusCode = statusCode
        self.startTime = startTime
        self.endTime = endTime
        self.requestBodySize = requestBodySize
        self.responseBodySize = responseBodySize
        self.tags = tags
    }
}
