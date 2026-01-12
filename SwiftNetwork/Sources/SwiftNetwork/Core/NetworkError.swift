//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// Represents errors that can occur during network request execution.
///
/// `NetworkError` encapsulates all failure cases produced by the networking
/// stack, including transport failures, decoding issues, cancellation,
/// and HTTP-level errors.
public enum NetworkError: Error, Sendable {

    /// The request was explicitly cancelled.
    case cancelled

    /// The received response was not a valid HTTP response.
    case invalidResponse

    /// A low-level transport error occurred.
    ///
    /// - Parameter Error: The underlying transport error.
    case transportError(Error)

    /// The response did not contain any body data when data was expected.
    case noData

    /// Failed to decode the response body.
    ///
    /// - Parameter Error: The underlying decoding error.
    case decodingError(Error)

    /// The server returned a non-successful HTTP status code.
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code returned by the server.
    ///   - body: The optional response body.
    case httpError(statusCode: Int, body: Data?)
}
