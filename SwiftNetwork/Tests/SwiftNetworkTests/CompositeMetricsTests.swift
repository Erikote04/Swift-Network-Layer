//
//  CompositeMetricsTests.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 21/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Composite Metrics Tests")
struct CompositeMetricsTests {
    
    @Test("CompositeMetrics forwards events to all collectors")
    func testForwardsToAllCollectors() async throws {
        let recorder1 = MetricsRecorder()
        let recorder2 = MetricsRecorder()
        let recorder3 = MetricsRecorder()
        
        let composite = CompositeMetrics(collectors: [recorder1, recorder2, recorder3])
        
        let event = RequestMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.5),
            responseBodySize: 1024
        )
        
        await composite.recordRequest(event)
        
        let events1 = await recorder1.requestEvents
        let events2 = await recorder2.requestEvents
        let events3 = await recorder3.requestEvents
        
        #expect(events1.count == 1)
        #expect(events2.count == 1)
        #expect(events3.count == 1)
    }
    
    @Test("CompositeMetrics forwards all event types")
    func testForwardsAllEventTypes() async throws {
        let recorder = MetricsRecorder()
        let composite = CompositeMetrics(collectors: [recorder])
        
        let requestEvent = RequestMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.5),
            responseBodySize: 1024
        )
        
        let errorEvent = ErrorMetricEvent(
            method: .post,
            url: URL(string: "https://api.example.com")!,
            error: .invalidResponse,
            startTime: Date(),
            errorTime: Date().addingTimeInterval(0.3)
        )
        
        let retryEvent = RetryMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            attemptNumber: 1,
            reason: "timeout",
            retryTime: Date()
        )
        
        let cacheEvent = CacheMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            result: .hit,
            timestamp: Date()
        )
        
        await composite.recordRequest(requestEvent)
        await composite.recordError(errorEvent)
        await composite.recordRetry(retryEvent)
        await composite.recordCacheHit(cacheEvent)
        
        let requests = await recorder.requestEvents
        let errors = await recorder.errorEvents
        let retries = await recorder.retryEvents
        let cache = await recorder.cacheEvents
        
        #expect(requests.count == 1)
        #expect(errors.count == 1)
        #expect(retries.count == 1)
        #expect(cache.count == 1)
    }
    
    @Test("CompositeMetrics works with ConsoleMetrics and AggregateMetrics")
    func testRealWorldComposition() async throws {
        let console = ConsoleMetrics()
        let aggregate = AggregateMetrics()
        let composite = CompositeMetrics(collectors: [console, aggregate])
        
        let event = RequestMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.5),
            responseBodySize: 1024
        )
        
        await composite.recordRequest(event)
        
        let snapshot = await aggregate.snapshot()
        #expect(snapshot.totalRequests == 1)
    }
}
