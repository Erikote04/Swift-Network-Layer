//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Testing
@testable import SwiftNetwork

@Suite("Smoke Tests", .tags(.smoke))
struct SmokeTests {

    @Test("Client executes a request")
    func clientExecutesRequest() async throws {
        let transport = FakeTransport { request in
            TestResponses.success(request: request)
        }

        let client = TestClientFactory.make(transport: transport)

        let request = Request(
            method: .get,
            url: URL(string: "https://example.com")!
        )

        _ = try await client.newCall(request).execute()

        let recorded = await transport.requests
        #expect(recorded.count == 1)
    }
}
