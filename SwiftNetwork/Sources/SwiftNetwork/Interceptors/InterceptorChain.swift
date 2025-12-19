//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

final class InterceptorChain: InterceptorChainProtocol, @unchecked Sendable {
    private let interceptors: [Interceptor]
    private let index: Int
    let request: Request
    private let terminalHandler: (Request) async throws -> Response

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
