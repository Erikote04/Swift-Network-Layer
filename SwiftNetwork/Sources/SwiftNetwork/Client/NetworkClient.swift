//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

public final class NetworkClient: NetworkClientProtocol {

    private let configuration: NetworkClientConfiguration

    public init(configuration: NetworkClientConfiguration = .init()) {
        self.configuration = configuration
    }

    public func newCall(_ request: Request) -> Call {
        let resolvedRequest = resolve(request)
        return StubCall(request: resolvedRequest)
    }

    private func resolve(_ request: Request) -> Request {
        var finalURL = request.url

        if let baseURL = configuration.baseURL,
           request.url.host == nil {
            finalURL = baseURL.appendingPathComponent(request.url.path)
        }

        let headers = configuration
            .defaultHeaders
            .merging(request.headers)

        let timeout = request.timeout ?? configuration.timeout

        return Request(
            method: request.method,
            url: finalURL,
            headers: headers,
            body: request.body,
            timeout: timeout
        )
    }
}
