//
//  HeaderInjectionInterceptor.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

struct HeaderInjectionInterceptor: Interceptor {
    let name: String
    let value: String

    func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        var headers = chain.request.headers
        headers[name] = value
        let updated = Request(
            method: chain.request.method,
            url: chain.request.url,
            headers: headers,
            body: chain.request.body,
            timeout: chain.request.timeout,
            cachePolicy: chain.request.cachePolicy,
            priority: chain.request.priority
        )

        return try await chain.proceed(updated)
    }
}
