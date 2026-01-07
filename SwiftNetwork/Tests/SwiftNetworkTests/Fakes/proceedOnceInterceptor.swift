//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Testing
@testable import SwiftNetwork

actor ProceedOnceInterceptor: Interceptor {

    private var called = false

    func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        #expect(called == false)
        called = true
        return try await chain.proceed(chain.request)
    }
}
