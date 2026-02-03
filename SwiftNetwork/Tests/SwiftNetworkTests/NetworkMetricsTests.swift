//
//  NetworkMetricsTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork on 21/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Network Metrics Tests", .tags(.metrics))
struct NetworkMetricsTests {
    
    @Test("MetricsInterceptor records successful request")
    func testSuccessfulRequestRecording() async throws {
        let recorder = MetricsRecorder()
        let interceptor = MetricsInterceptor(metrics: recorder)
        
        let transport = FakeTransport { request in
            Response(
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
            url: URL(string: "https://api.example.com/data")!
        )
        
        _ = try await client.newCall(request).execute()
        
        let events = await recorder.requestEvents
        #expect(events.count == 1)
        
        let event = try #require(events.first)
        #expect(event.statusCode == 200)
        #expect(event.method == .get)
        #expect(event.url.absoluteString == "https://api.example.com/data")
        #expect(event.duration > 0)
    }
    
    @Test("MetricsInterceptor records errors")
    func testErrorRecording() async throws {
        let recorder = MetricsRecorder()
        let interceptor = MetricsInterceptor(metrics: recorder)
        
        let transport = FakeTransport { _ in
            throw NetworkError.invalidResponse
        }
        
        let client = NetworkClient(
            transport: transport,
            interceptors: [interceptor]
        )
        
        let request = Request(
            method: .post,
            url: URL(string: "https://api.example.com/submit")!
        )
        
        _ = try? await client.newCall(request).execute()
        
        let events = await recorder.errorEvents
        #expect(events.count == 1)
        
        let event = try #require(events.first)
        #expect(event.method == .post)
        #expect(event.url.absoluteString == "https://api.example.com/submit")
    }
    
    @Test("MetricsInterceptor applies custom tags")
    func testCustomTags() async throws {
        let customTags = ["environment": "staging", "version": "1.0.0"]
        let recorder = MetricsRecorder()
        let interceptor = MetricsInterceptor(
            metrics: recorder,
            tags: customTags
        )
        
        let transport = FakeTransport { request in
            Response(
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
            url: URL(string: "https://api.example.com/data")!
        )
        
        _ = try await client.newCall(request).execute()
        
        let events = await recorder.requestEvents
        let event = try #require(events.first)
        #expect(event.tags["environment"] == "staging")
        #expect(event.tags["version"] == "1.0.0")
    }
    
    @Test("RequestMetricEvent calculates duration correctly")
    func testRequestMetricEventDuration() async throws {
        let start = Date()
        let end = start.addingTimeInterval(1.5)
        
        let event = RequestMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            startTime: start,
            endTime: end,
            responseBodySize: 1024
        )
        
        #expect(event.duration == 1.5)
    }
    
    @Test("ErrorMetricEvent calculates duration correctly")
    func testErrorMetricEventDuration() async throws {
        let start = Date()
        let errorTime = start.addingTimeInterval(0.75)
        
        let event = ErrorMetricEvent(
            method: .post,
            url: URL(string: "https://api.example.com")!,
            error: .invalidResponse,
            startTime: start,
            errorTime: errorTime
        )
        
        #expect(event.duration == 0.75)
    }
}

/// Test helper to record metrics events
actor MetricsRecorder: NetworkMetrics {
    
    private(set) var requestEvents: [RequestMetricEvent] = []
    private(set) var errorEvents: [ErrorMetricEvent] = []
    private(set) var retryEvents: [RetryMetricEvent] = []
    private(set) var cacheEvents: [CacheMetricEvent] = []
    
    func recordRequest(_ event: RequestMetricEvent) async {
        requestEvents.append(event)
    }
    
    func recordError(_ event: ErrorMetricEvent) async {
        errorEvents.append(event)
    }
    
    func recordRetry(_ event: RetryMetricEvent) async {
        retryEvents.append(event)
    }
    
    func recordCacheHit(_ event: CacheMetricEvent) async {
        cacheEvents.append(event)
    }
}
