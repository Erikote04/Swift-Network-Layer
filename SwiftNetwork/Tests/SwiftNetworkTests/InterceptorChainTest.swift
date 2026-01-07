//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Testing
@testable import SwiftNetwork

struct InterceptorChainTests {

    @Test
    func interceptorsExecuteInOrder() async throws {
        let recorder = Recorder()

        let interceptors: [Interceptor] = [
            RecordingInterceptor(id: "A", recorder: recorder),
            RecordingInterceptor(id: "B", recorder: recorder),
            RecordingInterceptor(id: "C", recorder: recorder)
        ]

        let transport = FakeTransport { request in
            TestResponses.success(request: request)
        }

        let client = TestClientFactory.make(
            transport: transport,
            interceptors: interceptors
        )

        let request = Request(
            method: .get,
            url: URL(string: "https://example.com")!
        )

        _ = try await client.newCall(request).execute()

        let events = await recorder.events
        #expect(events == ["A", "B", "C"])
    }
    
    @Test
    func interceptorCanModifyRequest() async throws {
        let interceptor = HeaderMutatingInterceptor(
            header: ("X-Test", "123")
        )

        let transport = FakeTransport { request in
            #expect(request.headers["X-Test"] == "123")
            return TestResponses.success(request: request)
        }

        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [interceptor]
        )

        let request = Request(
            method: .get,
            url: URL(string: "https://example.com")!
        )

        _ = try await client.newCall(request).execute()
    }

    @Test
    func proceedIsCalledOnlyOnce() async throws {
        let interceptor = ProceedOnceInterceptor()

        let transport = FakeTransport { request in
            TestResponses.success(request: request)
        }

        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [interceptor]
        )

        let request = Request(
            method: .get,
            url: URL(string: "https://example.com")!
        )

        _ = try await client.newCall(request).execute()
    }
}
