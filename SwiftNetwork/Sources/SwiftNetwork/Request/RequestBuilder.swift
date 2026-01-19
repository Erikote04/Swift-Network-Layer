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
    private var body: RequestBody?
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
    @discardableResult
    public mutating func header(_ name: String, _ value: String) -> Self {
        headers[name] = value
        return self
    }

    /// Merges multiple HTTP headers into the request.
    ///
    /// - Parameter headers: The headers to merge.
    /// - Returns: The updated builder instance.
    @discardableResult
    public mutating func headers(_ headers: HTTPHeaders) -> Self {
        self.headers = self.headers.merging(headers)
        return self
    }

    /// Sets the request body.
    ///
    /// - Parameter body: The request body.
    /// - Returns: The updated builder instance.
    @discardableResult
    public mutating func body(_ body: RequestBody?) -> Self {
        self.body = body
        return self
    }
    
    /// Sets the request body from raw data.
    ///
    /// This is a convenience method that wraps the data in a ``RequestBody/data(_:contentType:)`` case.
    ///
    /// - Parameters:
    ///   - data: The raw request body data.
    ///   - contentType: The MIME type of the data. Defaults to `application/octet-stream`.
    /// - Returns: The updated builder instance.
    @discardableResult
    public mutating func body(_ data: Data?, contentType: String = "application/octet-stream") -> Self {
        self.body = data.map { .data($0, contentType: contentType) }
        return self
    }
    
    /// Sets a JSON-encoded request body.
    ///
    /// The provided value will be JSON-encoded when the request is executed.
    ///
    /// - Parameters:
    ///   - value: Any `Encodable` value to be JSON-encoded.
    ///   - encoder: The `JSONEncoder` to use. Defaults to a new instance.
    /// - Returns: The updated builder instance.
    @discardableResult
    public mutating func jsonBody<T: Encodable & Sendable>(
        _ value: T,
        encoder: JSONEncoder = JSONEncoder()
    ) -> Self {
        self.body = .json(value, encoder: encoder)
        return self
    }
    
    /// Sets a form-encoded request body.
    ///
    /// The fields will be encoded as `application/x-www-form-urlencoded`.
    ///
    /// - Parameter fields: A dictionary of field names and values.
    /// - Returns: The updated builder instance.
    @discardableResult
    public mutating func formBody(_ fields: [String: String]) -> Self {
        self.body = .form(fields)
        return self
    }
    
    /// Sets a multipart/form-data request body.
    ///
    /// This method is used for file uploads and forms with mixed content types.
    /// Each part can contain text fields or binary file data.
    ///
    /// - Parameter parts: An array of multipart form data parts.
    /// - Returns: The updated builder instance.
    ///
    /// Example:
    /// ```swift
    /// let imageData = UIImage(named: "photo")!.pngData()!
    /// 
    /// var builder = RequestBuilder(method: .post, url: uploadURL)
    /// builder
    ///     .multipartBody([
    ///         MultipartFormData(name: "title", value: "My Photo"),
    ///         MultipartFormData(
    ///             name: "image",
    ///             filename: "photo.png",
    ///             data: imageData,
    ///             mimeType: "image/png"
    ///         )
    ///     ])
    ///     .build()
    /// ```
    @discardableResult
    public mutating func multipartBody(_ parts: [MultipartFormData]) -> Self {
        self.body = .multipart(parts)
        return self
    }

    /// Sets a custom timeout interval for the request.
    ///
    /// - Parameter interval: The timeout interval.
    /// - Returns: The updated builder instance.
    @discardableResult
    public mutating func timeout(_ interval: TimeInterval) -> Self {
        self.timeout = interval
        return self
    }

    /// Sets the cache policy for the request.
    ///
    /// - Parameter policy: The cache policy to apply.
    /// - Returns: The updated builder instance.
    @discardableResult
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
