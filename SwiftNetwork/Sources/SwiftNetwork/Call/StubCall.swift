//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

final class StubCall: BaseCall, @unchecked Sendable {
    override func performExecute() async throws -> Response {
        throw NetworkError.transportError(
            NSError(
                domain: "SwiftNetwork",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Transport not implemented"]
            )
        )
    }
}
