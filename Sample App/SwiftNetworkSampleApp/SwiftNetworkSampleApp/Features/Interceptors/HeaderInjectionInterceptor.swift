//
//  HeaderInjectionInterceptor.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

struct HeaderInjectionInterceptor: RequestInterceptor {
    let name: String
    let value: String

    func interceptRequest(_ request: Request) async throws -> Request {
        var headers = request.headers
        headers[name] = value
        return Request(
            method: request.method,
            url: request.url,
            headers: headers,
            body: request.body,
            timeout: request.timeout,
            cachePolicy: request.cachePolicy,
            priority: request.priority
        )
    }
}
