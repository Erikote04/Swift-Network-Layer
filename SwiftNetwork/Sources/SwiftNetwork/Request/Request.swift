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
/// including method, URL, headers, body, timeout, cache behavior, and priority.
public struct Request: Sendable {

    /// The HTTP method of the request.
    public let method: HTTPMethod

    /// The URL the request is sent to.
    public let url: URL

    /// The headers included in the request.
    public let headers: HTTPHeaders

    /// The optional HTTP body of the request.
    ///
    /// When set, the body is encoded according to its type and the appropriate
    /// Content-Type header is set automatically.
    ///
    /// - SeeAlso: ``RequestBody``
    public let body: RequestBody?

    /// An optional timeout interval specific to this request.
    public let timeout: TimeInterval?

    /// The cache policy applied to this request.
    public let cachePolicy: CachePolicy
    
    /// The priority of this request.
    ///
    /// Higher priority requests may be scheduled ahead of lower priority ones.
    /// Defaults to `.normal`.
    public let priority: RequestPriority

    /// Creates a new request.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use.
    ///   - url: The URL the request is sent to.
    ///   - headers: Headers included in the request.
    ///   - body: Optional request body. When provided, the body is encoded
    ///     and the Content-Type header is set automatically.
    ///   - timeout: Optional timeout interval for the request.
    ///   - cachePolicy: Defines how caching should be applied.
    ///   - priority: The execution priority of the request.
    public init(
        method: HTTPMethod,
        url: URL,
        headers: HTTPHeaders = [:],
        body: RequestBody? = nil,
        timeout: TimeInterval? = nil,
        cachePolicy: CachePolicy = .useCache,
        priority: RequestPriority = .normal
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.timeout = timeout
        self.cachePolicy = cachePolicy
        self.priority = priority
    }
    
    /// Creates a new request with raw data as the body.
    ///
    /// This convenience initializer maintains backward compatibility with code
    /// that passes `Data?` directly. The data is wrapped in a ``RequestBody/data(_:contentType:)``
    /// case automatically.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use.
    ///   - url: The URL the request is sent to.
    ///   - headers: Headers included in the request.
    ///   - bodyData: Optional raw request body data.
    ///   - timeout: Optional timeout interval for the request.
    ///   - cachePolicy: Defines how caching should be applied.
    ///   - priority: The execution priority of the request.
    @available(*, deprecated, message: "Use init(method:url:headers:body:timeout:cachePolicy:priority:) with RequestBody instead")
    public init(
        method: HTTPMethod,
        url: URL,
        headers: HTTPHeaders = [:],
        bodyData: Data?,
        timeout: TimeInterval? = nil,
        cachePolicy: CachePolicy = .useCache,
        priority: RequestPriority = .normal
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = bodyData.map { .data($0) }
        self.timeout = timeout
        self.cachePolicy = cachePolicy
        self.priority = priority
    }
}
