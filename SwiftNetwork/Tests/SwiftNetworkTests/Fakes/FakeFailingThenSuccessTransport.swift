//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 8/1/26.
//

import Testing
@testable import SwiftNetwork

actor FakeFailingThenSuccessTransport: Transport {

    private var remainingFailures: Int
    private let error: NetworkError
    private let successResponse: Response

    private(set) var calls = 0

    init(
        failures: Int,
        error: NetworkError,
        successResponse: Response
    ) {
        self.remainingFailures = failures
        self.error = error
        self.successResponse = successResponse
    }

    func execute(_ request: Request) async throws -> Response {
        calls += 1

        if remainingFailures > 0 {
            remainingFailures -= 1
            throw error
        }

        return successResponse
    }
}
