//
//  RetryInterceptorMetricsTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork on 21/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Retry Interceptor Metrics Tests")
struct RetryInterceptorMetricsTests {
    
    @Test("RetryInterceptor records retry attempts")
    func testRetryRecording() async throws {
        let recorder = MetricsRecorder()
        let interceptor = RetryInterceptor(
            maxRetries: 2,
            delay: 0.01,
            metrics: recorder
        )
        
        let counter = CallCounter()
        let transport = FakeTransport { request in
            let count = await counter.increment()
            if count <= 2 {
                throw NetworkError.transportError(
                    NSError(domain: "test", code: -1)
                )
            }
            return Response(
                request: request,
                statusCode: 200,
                headers: [:],
                body: Data()
            )
        }
        
        let client = NetworkClient(
            transport: transport,
            interceptors: [interceptor]
        )
        
        let request = Request(
            method: .get,
            url: URL(string: "https://api.example.com")!
        )
        
        _ = try await client.newCall(request).execute()
        
        let retries = await recorder.retryEvents
        #expect(retries.count == 2)
        #expect(retries[0].attemptNumber == 1)
        #expect(retries[1].attemptNumber == 2)
    }
}
