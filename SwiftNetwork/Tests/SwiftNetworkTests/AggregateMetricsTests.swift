//
//  AggregateMetricsTests.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 21/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Aggregate Metrics Tests")
struct AggregateMetricsTests {
    
    @Test("AggregateMetrics tracks successful requests")
    func testSuccessfulRequestTracking() async throws {
        let metrics = AggregateMetrics()
        
        let event = RequestMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.5),
            responseBodySize: 1024
        )
        
        await metrics.recordRequest(event)
        
        let snapshot = await metrics.snapshot()
        #expect(snapshot.totalRequests == 1)
        #expect(snapshot.successfulRequests == 1)
        #expect(snapshot.failedRequests == 0)
        #expect(snapshot.successRate == 100.0)
    }
    
    @Test("AggregateMetrics tracks failed requests")
    func testFailedRequestTracking() async throws {
        let metrics = AggregateMetrics()
        
        let errorEvent = ErrorMetricEvent(
            method: .post,
            url: URL(string: "https://api.example.com")!,
            error: .invalidResponse,
            startTime: Date(),
            errorTime: Date().addingTimeInterval(0.3)
        )
        
        await metrics.recordError(errorEvent)
        
        let snapshot = await metrics.snapshot()
        #expect(snapshot.totalRequests == 1)
        #expect(snapshot.successfulRequests == 0)
        #expect(snapshot.failedRequests == 1)
        #expect(snapshot.successRate == 0.0)
    }
    
    @Test("AggregateMetrics calculates percentiles correctly")
    func testPercentileCalculation() async throws {
        let metrics = AggregateMetrics()
        
        // Record requests with known durations
        let durations = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
        
        for duration in durations {
            let event = RequestMetricEvent(
                method: .get,
                url: URL(string: "https://api.example.com")!,
                statusCode: 200,
                startTime: Date(),
                endTime: Date().addingTimeInterval(duration),
                responseBodySize: 100
            )
            await metrics.recordRequest(event)
        }
        
        let snapshot = await metrics.snapshot()
        #expect(snapshot.averageDuration == 0.55)
        #expect(snapshot.medianDuration == 0.5)
        #expect(snapshot.p95Duration >= 0.9)
    }
    
    @Test("AggregateMetrics tracks retries")
    func testRetryTracking() async throws {
        let metrics = AggregateMetrics()
        
        let retry1 = RetryMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            attemptNumber: 1,
            reason: "timeout",
            retryTime: Date()
        )
        
        let retry2 = RetryMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            attemptNumber: 2,
            reason: "network error",
            retryTime: Date()
        )
        
        await metrics.recordRetry(retry1)
        await metrics.recordRetry(retry2)
        
        let snapshot = await metrics.snapshot()
        #expect(snapshot.totalRetries == 2)
    }
    
    @Test("AggregateMetrics tracks cache hits and misses")
    func testCacheTracking() async throws {
        let metrics = AggregateMetrics()
        
        let hit = CacheMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            result: .hit,
            timestamp: Date()
        )
        
        let miss = CacheMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            result: .miss,
            timestamp: Date()
        )
        
        await metrics.recordCacheHit(hit)
        await metrics.recordCacheHit(miss)
        await metrics.recordCacheHit(hit)
        
        let snapshot = await metrics.snapshot()
        #expect(snapshot.cacheHits == 2)
        #expect(snapshot.cacheMisses == 1)
        #expect(snapshot.cacheHitRate == 66.66666666666666)
    }
    
    @Test("AggregateMetrics resets correctly")
    func testReset() async throws {
        let metrics = AggregateMetrics()
        
        let event = RequestMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.5),
            responseBodySize: 1024
        )
        
        await metrics.recordRequest(event)
        await metrics.reset()
        
        let snapshot = await metrics.snapshot()
        #expect(snapshot.totalRequests == 0)
        #expect(snapshot.successfulRequests == 0)
        #expect(snapshot.totalBytesReceived == 0)
    }
}
