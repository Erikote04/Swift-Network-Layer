//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

final class InterceptorCall: BaseCall {
    private let interceptors: [Interceptor]
    private let transport: Transport

    init(
        request: Request,
        interceptors: [Interceptor],
        transport: Transport
    ) {
        self.interceptors = interceptors
        self.transport = transport
        super.init(request: request)
    }

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
