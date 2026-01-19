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
/// for uploads and downloads when the transport is `URLSessionTransport`.
final class TransportCall: BaseCall, ProgressCall, @unchecked Sendable {

    private let transport: Transport

    /// Creates a new transport-backed call.
    ///
    /// - Parameters:
    ///   - request: The request to execute.
    ///   - transport: The transport responsible for executing the request.
    init(request: Request, transport: Transport) {
        self.transport = transport
        super.init(request: request)
    }

    /// Executes the request using the underlying transport.
    ///
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error produced by the transport.
    override func performExecute() async throws -> Response {
        try await transport.execute(request)
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
        // Check if transport supports progress
        if let urlSessionTransport = transport as? URLSessionTransport {
            return try await urlSessionTransport.execute(request, progress: progress)
        }
        
        // Fallback to regular execution
        return try await execute()
    }
}
