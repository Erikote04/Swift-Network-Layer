//
//  FilteredMetricsTests.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 21/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Filtered Metrics Tests", .tags(.metrics))
struct FilteredMetricsTests {
    
    @Test("FilteredMetrics filters by custom predicate")
    func testCustomFilter() async throws {
        let recorder = MetricsRecorder()
        
        // Only record GET requests
        let filtered = FilteredMetrics(collector: recorder) { event in
            event.method == .get
        }
        
        let getEvent = RequestMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.5),
            responseBodySize: 1024
        )
        
        let postEvent = RequestMetricEvent(
            method: .post,
            url: URL(string: "https://api.example.com")!,
            statusCode: 201,
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.5),
            responseBodySize: 512
        )
        
        await filtered.recordRequest(getEvent)
        await filtered.recordRequest(postEvent)
        
        let events = await recorder.requestEvents
        #expect(events.count == 1)
        #expect(events[0].method == .get)
    }
    
    @Test("FilteredMetrics.methods filters by HTTP method")
    func testMethodsFilter() async throws {
        let recorder = MetricsRecorder()
        let filtered = FilteredMetrics.methods([.get, .post], collector: recorder)
        
        let getEvent = RequestMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.5),
            responseBodySize: 1024
        )
        
        let deleteEvent = RequestMetricEvent(
            method: .delete,
            url: URL(string: "https://api.example.com")!,
            statusCode: 204,
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.3),
            responseBodySize: 0
        )
        
        await filtered.recordRequest(getEvent)
        await filtered.recordRequest(deleteEvent)
        
        let events = await recorder.requestEvents
        #expect(events.count == 1)
        #expect(events[0].method == .get)
    }
    
    @Test("FilteredMetrics.urlPattern filters by URL pattern")
    func testUrlPatternFilter() async throws {
        let recorder = MetricsRecorder()
        let filtered = FilteredMetrics.urlPattern("/api/.*", collector: recorder)
        
        let apiEvent = RequestMetricEvent(
            method: .get,
            url: URL(string: "https://example.com/api/users")!,
            statusCode: 200,
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.5),
            responseBodySize: 1024
        )
        
        let webEvent = RequestMetricEvent(
            method: .get,
            url: URL(string: "https://example.com/web/page")!,
            statusCode: 200,
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.5),
            responseBodySize: 2048
        )
        
        await filtered.recordRequest(apiEvent)
        await filtered.recordRequest(webEvent)
        
        let events = await recorder.requestEvents
        #expect(events.count == 1)
        #expect(events[0].url.absoluteString.contains("/api/"))
    }
    
    @Test("FilteredMetrics.errorsOnly filters only errors")
    func testErrorsOnlyFilter() async throws {
        let recorder = MetricsRecorder()
        let filtered = FilteredMetrics.errorsOnly(collector: recorder)
        
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
        
        await filtered.recordRequest(requestEvent)
        await filtered.recordError(errorEvent)
        
        let requests = await recorder.requestEvents
        let errors = await recorder.errorEvents
        
        #expect(requests.count == 0)
        #expect(errors.count == 1)
    }
    
    @Test("FilteredMetrics.successOnly filters only successful requests")
    func testSuccessOnlyFilter() async throws {
        let recorder = MetricsRecorder()
        let filtered = FilteredMetrics.successOnly(collector: recorder)
        
        let successEvent = RequestMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.5),
            responseBodySize: 1024
        )
        
        let errorEvent = RequestMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            statusCode: 500,
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.5),
            responseBodySize: 100
        )
        
        await filtered.recordRequest(successEvent)
        await filtered.recordRequest(errorEvent)
        
        let events = await recorder.requestEvents
        #expect(events.count == 1)
        #expect(events[0].statusCode == 200)
    }
    
    @Test("FilteredMetrics.tags filters by tags")
    func testTagsFilter() async throws {
        let recorder = MetricsRecorder()
        let filtered = FilteredMetrics.tags(
            ["environment": "production"],
            collector: recorder
        )
        
        let prodEvent = RequestMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.5),
            responseBodySize: 1024,
            tags: ["environment": "production", "version": "1.0"]
        )
        
        let stagingEvent = RequestMetricEvent(
            method: .get,
            url: URL(string: "https://api.example.com")!,
            statusCode: 200,
            startTime: Date(),
            endTime: Date().addingTimeInterval(0.5),
            responseBodySize: 1024,
            tags: ["environment": "staging", "version": "1.0"]
        )
        
        await filtered.recordRequest(prodEvent)
        await filtered.recordRequest(stagingEvent)
        
        let events = await recorder.requestEvents
        #expect(events.count == 1)
        #expect(events[0].tags["environment"] == "production")
    }
}
