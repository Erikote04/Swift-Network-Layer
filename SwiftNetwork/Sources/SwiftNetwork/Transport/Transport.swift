//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// A protocol defining a low-level network transport.
///
/// `Transport` is responsible for executing a fully constructed `Request`
/// and returning a `Response`. It represents the final execution layer of
/// the networking stack, after all interceptors have been applied.
protocol Transport: Sendable {

    /// Executes the given request.
    ///
    /// - Parameter request: The request to execute.
    /// - Returns: A `Response` representing the result of the request.
    /// - Throws: A `NetworkError` if the request fails or is cancelled.
    func execute(_ request: Request) async throws -> Response
}

/// A transport that can report progress during execution.
protocol ProgressReportingTransport: Transport {

    /// Executes the given request with optional progress reporting.
    ///
    /// - Parameters:
    ///   - request: The request to execute.
    ///   - progress: An optional closure to receive progress updates.
    /// - Returns: A `Response` representing the result of the request.
    /// - Throws: A `NetworkError` if the request fails or is cancelled.
    func execute(
        _ request: Request,
        progress: (@Sendable (Progress) -> Void)?
    ) async throws -> Response
}

/// A transport that can stream response bodies.
protocol StreamingTransport: Transport {

    /// Streams the response for the given request.
    ///
    /// - Parameter request: The request to execute.
    /// - Returns: A `StreamingResponse` containing headers and a data stream.
    /// - Throws: A `NetworkError` if the request fails or is cancelled.
    func stream(_ request: Request) async throws -> StreamingResponse
}
