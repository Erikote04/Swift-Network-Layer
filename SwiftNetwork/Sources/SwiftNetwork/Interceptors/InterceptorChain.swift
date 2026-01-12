//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// The concrete implementation of an interceptor chain.
///
/// `InterceptorChain` is responsible for invoking interceptors sequentially
/// and eventually delegating execution to the terminal handler.
final class InterceptorChain: InterceptorChainProtocol, @unchecked Sendable {

    private let interceptors: [Interceptor]
    private let index: Int
    let request: Request
    private let terminalHandler: (Request) async throws -> Response

    /// Creates a new interceptor chain.
    ///
    /// - Parameters:
    ///   - interceptors: The full list of interceptors.
    ///   - index: The current interceptor index.
    ///   - request: The current request.
    ///   - terminalHandler: The final request executor.
    init(
        interceptors: [Interceptor],
        index: Int,
        request: Request,
        terminalHandler: @escaping (Request) async throws -> Response
    ) {
        self.interceptors = interceptors
        self.index = index
        self.request = request
        self.terminalHandler = terminalHandler
    }

    /// Proceeds to the next interceptor or executes the terminal handler.
    ///
    /// - Parameter request: The request to forward.
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error produced during interception.
    func proceed(_ request: Request) async throws -> Response {
        if index < interceptors.count {
            let next = InterceptorChain(
                interceptors: interceptors,
                index: index + 1,
                request: request,
                terminalHandler: terminalHandler
            )
            return try await interceptors[index].intercept(next)
        } else {
            return try await terminalHandler(request)
        }
    }
}
