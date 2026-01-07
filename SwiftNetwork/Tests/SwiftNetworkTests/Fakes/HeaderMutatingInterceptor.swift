//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Foundation
@testable import SwiftNetwork

struct HeaderMutatingInterceptor: Interceptor {

    let header: (String, String)

    func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        var headers = chain.request.headers
        headers[header.0] = header.1

        let modified = Request(
            method: chain.request.method,
            url: chain.request.url,
            headers: headers,
            body: chain.request.body,
            timeout: chain.request.timeout,
            cachePolicy: chain.request.cachePolicy
        )

        return try await chain.proceed(modified)
    }
}
