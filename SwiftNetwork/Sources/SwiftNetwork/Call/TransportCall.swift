//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// A call implementation that directly delegates execution to a transport.
///
/// `TransportCall` bypasses interceptors and executes the request
/// directly using the provided `Transport`.
final class TransportCall: BaseCall, @unchecked Sendable {

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
}
