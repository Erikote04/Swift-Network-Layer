//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// A call implementation that executes a request through a chain of interceptors.
///
/// `InterceptorCall` composes multiple `Interceptor` instances and
/// ultimately delegates the request execution to a `Transport`.
final class InterceptorCall: BaseCall, @unchecked Sendable {

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
        let chain = InterceptorChain(
            interceptors: interceptors,
            index: 0,
            request: request
        ) { request in
            try await self.transport.execute(request)
        }

        return try await chain.proceed(request)
    }
}
