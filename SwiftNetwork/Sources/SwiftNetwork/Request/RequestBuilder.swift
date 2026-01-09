//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// A mutable builder for constructing `Request` instances.
///
/// `RequestBuilder` provides a fluent API for incrementally configuring
/// request parameters before producing an immutable `Request`.
public struct RequestBuilder {

    private var method: HTTPMethod
    private var url: URL
    private var headers: HTTPHeaders = [:]
    private var body: Data?
    private var timeout: TimeInterval?
    private var cachePolicy: CachePolicy = .useCache

    /// Creates a new request builder.
    ///
    /// - Parameters:
    ///   - method: The HTTP method of the request.
    ///   - url: The URL the request is sent to.
    public init(method: HTTPMethod, url: URL) {
        self.method = method
        self.url = url
    }

    /// Adds or updates a single HTTP header.
    ///
    /// - Parameters:
    ///   - name: The header name.
    ///   - value: The header value.
    /// - Returns: The updated builder instance.
    public mutating func header(_ name: String, _ value: String) -> Self {
        headers[name] = value
        return self
    }

    /// Merges multiple HTTP headers into the request.
    ///
    /// - Parameter headers: The headers to merge.
    /// - Returns: The updated builder instance.
    public mutating func headers(_ headers: HTTPHeaders) -> Self {
        self.headers = self.headers.merging(headers)
        return self
    }

    /// Sets the request body.
    ///
    /// - Parameter data: The request body data.
    /// - Returns: The updated builder instance.
    public mutating func body(_ data: Data?) -> Self {
        self.body = data
        return self
    }

    /// Sets a custom timeout interval for the request.
    ///
    /// - Parameter interval: The timeout interval.
    /// - Returns: The updated builder instance.
    public mutating func timeout(_ interval: TimeInterval) -> Self {
        self.timeout = interval
        return self
    }

    /// Sets the cache policy for the request.
    ///
    /// - Parameter policy: The cache policy to apply.
    /// - Returns: The updated builder instance.
    public mutating func cachePolicy(_ policy: CachePolicy) -> Self {
        self.cachePolicy = policy
        return self
    }

    /// Builds an immutable `Request` from the configured values.
    ///
    /// - Returns: A fully configured `Request`.
    public func build() -> Request {
        Request(
            method: method,
            url: url,
            headers: headers,
            body: body,
            timeout: timeout,
            cachePolicy: cachePolicy
        )
    }
}
