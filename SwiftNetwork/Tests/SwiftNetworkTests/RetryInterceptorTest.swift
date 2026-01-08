//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 8/1/26.
//

import Testing
@testable import SwiftNetwork

struct RetryInterceptorTests {

    struct DummyError: Error {}

    @Test
    func retriesOnTransportErrorUntilSuccess() async throws {
        let request = Request(
            method: .get,
            url: URL(string: "https://example.com")!
        )

        let successResponse = Response(
            request: request,
            statusCode: 200,
            headers: [:],
            body: Data("ok".utf8)
        )

        let transport = FakeFailingThenSuccessTransport(
            failures: 2,
            error: .transportError(DummyError()),
            successResponse: successResponse
        )

        let interceptor = RetryInterceptor(
            maxRetries: 3,
            delay: 0
        )

        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [interceptor]
        )

        let response = try await client
            .newCall(request)
            .execute()

        #expect(response.statusCode == 200)
        #expect(await transport.calls == 3)
    }

    @Test
    func stopsRetryingAfterMaxRetries() async throws {
        let request = Request(
            method: .get,
            url: URL(string: "https://example.com")!
        )

        let successResponse = Response(
            request: request,
            statusCode: 200,
            headers: [:],
            body: Data()
        )

        let transport = FakeFailingThenSuccessTransport(
            failures: 10,
            error: .transportError(DummyError()),
            successResponse: successResponse
        )

        let interceptor = RetryInterceptor(
            maxRetries: 2,
            delay: 0
        )

        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [interceptor]
        )

        do {
            _ = try await client
                .newCall(request)
                .execute()

            Issue.record("Expected retry to exhaust and throw")
        } catch let error as NetworkError {
            switch error {
            case .transportError: #expect(await transport.calls == 3)
            default: Issue.record("Unexpected error type")
            }
        }
    }

    @Test
    func doesNotRetryOnCancelledError() async throws {
        let request = Request(
            method: .get,
            url: URL(string: "https://example.com")!
        )

        let successResponse = Response(
            request: request,
            statusCode: 200,
            headers: [:],
            body: Data()
        )

        let transport = FakeFailingThenSuccessTransport(
            failures: 1,
            error: .cancelled,
            successResponse: successResponse
        )

        let interceptor = RetryInterceptor(
            maxRetries: 3,
            delay: 0
        )

        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [interceptor]
        )

        do {
            _ = try await client
                .newCall(request)
                .execute()

            Issue.record("Expected cancelled error")
        } catch let error as NetworkError {
            switch error {
            case .cancelled: #expect(await transport.calls == 1)
            default: Issue.record("Unexpected error type")
            }
        }
    }
}
