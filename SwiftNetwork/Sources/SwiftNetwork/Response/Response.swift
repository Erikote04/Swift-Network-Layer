//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// An immutable representation of an HTTP response.
///
/// `Response` contains the result of a completed network request,
/// including the originating request, status code, headers, and body data.
public struct Response: Sendable {

    /// The original request that produced this response.
    public let request: Request

    /// The HTTP status code returned by the server.
    public let statusCode: Int

    /// The headers included in the response.
    public let headers: HTTPHeaders

    /// The optional response body data.
    public let body: Data?

    /// Creates a new response.
    ///
    /// - Parameters:
    ///   - request: The request associated with this response.
    ///   - statusCode: The HTTP status code returned by the server.
    ///   - headers: The response headers.
    ///   - body: Optional response body data.
    public init(
        request: Request,
        statusCode: Int,
        headers: HTTPHeaders = [:],
        body: Data? = nil
    ) {
        self.request = request
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

public extension Response {

    /// Indicates whether the response represents a successful HTTP result.
    ///
    /// A response is considered successful when its status code is in the
    /// `200..<300` range.
    var isSuccessful: Bool {
        (200..<300).contains(statusCode)
    }
}
