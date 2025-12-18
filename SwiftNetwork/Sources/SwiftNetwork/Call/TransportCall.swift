//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

final class TransportCall: BaseCall, @unchecked Sendable {

    private let transport: Transport

    init(request: Request, transport: Transport) {
        self.transport = transport
        super.init(request: request)
    }

    override func performExecute() async throws -> Response {
        try await transport.execute(request)
    }
}
