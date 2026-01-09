//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// An immutable representation of an HTTP request.
///
/// `Request` contains all the information required to perform a network call,
/// including method, URL, headers, body, timeout, and cache behavior.
public struct Request: Sendable {

    /// The HTTP method of the request.
    public let method: HTTPMethod

    /// The URL the request is sent to.
    public let url: URL

    /// The headers included in the request.
    public let headers: HTTPHeaders

    /// The optional HTTP body of the request.
    public let body: Data?

    /// An optional timeout interval specific to this request.
    public let timeout: TimeInterval?

    /// The cache policy applied to this request.
    public let cachePolicy: CachePolicy

    /// Creates a new request.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use.
    ///   - url: The URL the request is sent to.
    ///   - headers: Headers included in the request.
    ///   - body: Optional request body data.
    ///   - timeout: Optional timeout interval for the request.
    ///   - cachePolicy: Defines how caching should be applied.
    public init(
        method: HTTPMethod,
        url: URL,
        headers: HTTPHeaders = [:],
        body: Data? = nil,
        timeout: TimeInterval? = nil,
        cachePolicy: CachePolicy = .useCache
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.timeout = timeout
        self.cachePolicy = cachePolicy
    }
}
