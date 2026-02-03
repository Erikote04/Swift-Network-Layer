//
//  InterceptorCall.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// A call implementation that executes a request through a chain of interceptors.
///
/// `InterceptorCall` composes multiple `Interceptor` instances and
/// ultimately delegates the request execution to a `Transport`. It supports
/// progress reporting and streaming when the underlying transport supports them.
final class InterceptorCall: BaseCall, ProgressCall, StreamingCall {

    private let interceptors: [Interceptor]
    private let transport: Transport

    /// Creates a new interceptor-based call.
    ///
    /// - Parameters:
    ///   - request: The request to execute.
    ///   - interceptors: The interceptors applied to the request.
    ///   - transport: The transport responsible for executing the request.
    init(
        request: Request,
        interceptors: [Interceptor],
        transport: Transport
    ) {
        self.interceptors = interceptors
        self.transport = transport
        super.init(request: request)
    }

    /// Executes the interceptor chain and ultimately the transport.
    ///
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error produced by an interceptor or the transport.
    override func performExecute() async throws -> Response {
        try await performExecute(progress: nil)
    }
    
    /// Executes the interceptor chain with progress reporting.
    ///
    /// The progress handler is passed through to the final transport call.
    /// Interceptors cannot currently observe or modify progress reporting.
    ///
    /// - Parameter progress: A closure called with progress updates.
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error produced by an interceptor or the transport.
    public func execute(
        progress: @escaping @Sendable (Progress) -> Void
    ) async throws -> Response {
        try beginExecution()
        
        defer { finishExecution() }

        if isCancelled {
            throw NetworkError.cancelled
        }

        return try await performExecute(progress: progress)
    }
    
    /// Internal execution with optional progress handler.
    ///
    /// - Parameter progress: An optional progress handler.
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error produced by an interceptor or the transport.
    private func performExecute(
        progress: (@Sendable (Progress) -> Void)?
    ) async throws -> Response {
        let chain = InterceptorChain(
            interceptors: interceptors,
            index: 0,
            request: request
        ) { [transport] request in
            // If progress handler exists and transport supports it, use it
            if let progressHandler = progress,
               let urlSessionTransport = transport as? URLSessionTransport {
                return try await urlSessionTransport.execute(request, progress: progressHandler)
            }
            
            // Otherwise, use regular execution
            return try await transport.execute(request)
        }

        return try await chain.proceed(request)
    }
    
    /// Streams the response data as chunks.
    ///
    /// Streaming bypasses the interceptor chain and goes directly to the transport.
    /// This is because interceptors typically need the complete response to operate.
    ///
    /// - Returns: An `AsyncThrowingStream` of data chunks.
    public func stream() -> AsyncThrowingStream<Data, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Check if transport supports streaming
                    if let urlSessionTransport = transport as? URLSessionTransport {
                        let streamingResponse = try await urlSessionTransport.stream(request)
                        
                        for try await chunk in streamingResponse.stream {
                            continuation.yield(chunk)
                        }
                        
                        continuation.finish()
                    } else {
                        // Fallback: execute through interceptor chain and yield as single chunk
                        let response = try await performExecute(progress: nil)
                        
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
    
    // MARK: - Private Helpers (duplicated from BaseCall)
    
    private let state = ManagedCriticalState<CallState>(.idle)
    
    private func beginExecution() throws {
        state.withCriticalRegion { currentState in
            guard currentState == .idle else {
                fatalError("Call can only be executed once")
            }

            currentState = .running
        }
    }

    private func finishExecution() {
        state.withCriticalRegion { currentState in
            if currentState != .cancelled {
                currentState = .completed
            }
        }
    }
}
