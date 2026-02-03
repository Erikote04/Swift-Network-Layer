//
//  TransportCall.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// A call implementation that directly delegates execution to a transport.
///
/// `TransportCall` bypasses interceptors and executes the request
/// directly using the provided `Transport`. It supports progress reporting
/// and streaming for uploads and downloads when the transport is `URLSessionTransport`.
struct TransportCall: ProgressCall, StreamingCall {

    private let transport: Transport
    let request: Request
    private let stateController = CallStateController()

    /// Creates a new transport-backed call.
    ///
    /// - Parameters:
    ///   - request: The request to execute.
    ///   - transport: The transport responsible for executing the request.
    init(request: Request, transport: Transport) {
        self.request = request
        self.transport = transport
    }

    /// Executes the request using the underlying transport.
    ///
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error produced by the transport.
    func execute() async throws -> Response {
        try await stateController.beginExecution()

        defer { Task { await stateController.finishExecution() } }

        if await stateController.isCancelled() {
            throw NetworkError.cancelled
        }

        return try await transport.execute(request)
    }
    
    /// Executes the request with progress reporting.
    ///
    /// Progress reporting is only supported when the transport is `URLSessionTransport`.
    /// For other transports, this behaves the same as `execute()`.
    ///
    /// - Parameter progress: A closure called with progress updates.
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error produced by the transport.
    public func execute(
        progress: @escaping @Sendable (Progress) -> Void
    ) async throws -> Response {
        try await stateController.beginExecution()

        defer { Task { await stateController.finishExecution() } }

        if await stateController.isCancelled() {
            throw NetworkError.cancelled
        }

        // Check if transport supports progress
        if let progressTransport = transport as? ProgressReportingTransport {
            return try await progressTransport.execute(request, progress: progress)
        }
        
        // Fallback to regular execution
        return try await transport.execute(request)
    }
    
    /// Streams the response data as chunks.
    ///
    /// Streaming is only supported when the transport is `URLSessionTransport`.
    /// For other transports, this falls back to loading the entire response
    /// and yielding it as a single chunk.
    ///
    /// - Returns: An `AsyncThrowingStream` of data chunks.
    public func stream() -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Check if transport supports streaming
                    if let streamingTransport = transport as? StreamingTransport {
                        let streamingResponse = try await streamingTransport.stream(request)
                        
                        for try await chunk in streamingResponse.stream {
                            continuation.yield(chunk)
                        }
                        
                        continuation.finish()
                    } else {
                        // Fallback: execute normally and yield as single chunk
                        let response = try await execute()
                        
                        if let body = response.body, !body.isEmpty {
                            continuation.yield(body)
                        }
                        
                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Call

    func cancel() async {
        await stateController.cancel()
    }

    func isCancelled() async -> Bool {
        await stateController.isCancelled()
    }
}
