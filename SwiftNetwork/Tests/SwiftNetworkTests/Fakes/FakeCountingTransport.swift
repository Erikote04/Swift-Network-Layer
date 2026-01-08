//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 8/1/26.
//

import Foundation
@testable import SwiftNetwork

actor FakeCountingTransport: Transport {

    private(set) var calls = 0
    private let response: Response

    init(response: Response) {
        self.response = response
    }

    func execute(_ request: Request) async throws -> Response {
        calls += 1
        return response
    }
}
