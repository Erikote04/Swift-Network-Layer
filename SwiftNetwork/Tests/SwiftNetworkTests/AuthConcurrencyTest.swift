//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Testing
@testable import SwiftNetwork

struct AuthConcurrencyTests {

    @Test
    func multipleRequestsTriggerSingleTokenRefresh() async throws {
        let tokenStore = FakeTokenStore(initialToken: "expired")
        let authenticator = FakeAuthenticator(newToken: "valid")

        let authInterceptor = AuthInterceptor(
            tokenStore: tokenStore,
            authenticator: authenticator
        )

        let transport = AuthFailingTransport()

        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [authInterceptor]
        )

        let request = Request(
            method: .get,
            url: URL(string: "https://example.com")!
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    let response = try await client
                        .newCall(request)
                        .execute()

                    #expect(response.statusCode == 200)
                }
            }

            try await group.waitForAll()
        }

        let calls = await authenticator.authenticateCalls
        let updates = await tokenStore.updates

        #expect(calls == 1)
        #expect(updates == 1)
    }
}
