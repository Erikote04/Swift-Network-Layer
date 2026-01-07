//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Foundation
@testable import SwiftNetwork

actor FakeTransport: Transport {

    struct RecordedRequest: Sendable {
        let request: Request
    }

    private(set) var requests: [RecordedRequest] = []

    var handler: @Sendable (Request) async throws -> Response

    init(
        handler: @escaping @Sendable (Request) async throws -> Response
    ) {
        self.handler = handler
    }

    func execute(_ request: Request) async throws -> Response {
        requests.append(.init(request: request))
        return try await handler(request)
    }
}
