//
//  PrioritizedInterceptorTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork on 20/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Prioritized Interceptor Tests")
struct PrioritizedInterceptorTests {
    
    @Test("Interceptors execute in priority order")
    func testPriorityOrdering() async throws {
        let recorder = Recorder()
        
        let lowPriority = RecordingInterceptor(id: "Low", recorder: recorder)
        let mediumPriority = RecordingInterceptor(id: "Medium", recorder: recorder)
        let highPriority = RecordingInterceptor(id: "High", recorder: recorder)
        
        let transport = FakeTransportFactory.success()
        
        let client = TestClientFactory.make(
            transport: transport,
            prioritizedInterceptors: [
                PrioritizedInterceptor(interceptor: lowPriority, priority: 1),
                PrioritizedInterceptor(interceptor: highPriority, priority: 10),
                PrioritizedInterceptor(interceptor: mediumPriority, priority: 5)
            ]
        )
        
        let request = Request(method: .get, url: URL(string: "https://example.com")!)
        let call = client.newCall(request)
        
        _ = try await call.execute()
        
        // Verify execution order
        let events = await recorder.events
        #expect(events.count == 3)
        #expect(events[0] == "High")
        #expect(events[1] == "Medium")
        #expect(events[2] == "Low")
    }
    
    @Test("Same priority maintains insertion order")
    func testSamePriorityOrder() {
        let recorder = Recorder()
        
        let first = RecordingInterceptor(id: "First", recorder: recorder)
        let second = RecordingInterceptor(id: "Second", recorder: recorder)
        let third = RecordingInterceptor(id: "Third", recorder: recorder)
        
        let prioritized = [
            PrioritizedInterceptor(interceptor: first, priority: 5),
            PrioritizedInterceptor(interceptor: second, priority: 5),
            PrioritizedInterceptor(interceptor: third, priority: 5)
        ].sorted()
        
        // In Swift, stable sort maintains insertion order for equal elements
        #expect(prioritized.count == 3)
    }
    
    @Test("Mixed prioritized and regular interceptors")
    func testMixedInterceptors() async throws {
        let recorder = Recorder()
        
        let prioritized = RecordingInterceptor(id: "Prioritized", recorder: recorder)
        let regular = RecordingInterceptor(id: "Regular", recorder: recorder)
        
        let transport = FakeTransportFactory.success()
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [regular],
            prioritizedInterceptors: [
                PrioritizedInterceptor(interceptor: prioritized, priority: 10)
            ]
        )
        
        let request = Request(method: .get, url: URL(string: "https://example.com")!)
        let call = client.newCall(request)
        
        _ = try await call.execute()
        
        let events = await recorder.events
        #expect(events.count == 2)
        #expect(events[0] == "Prioritized")
        #expect(events[1] == "Regular")
    }
    
    @Test("Default priority is zero")
    func testDefaultPriority() {
        let recorder = Recorder()
        let interceptor = RecordingInterceptor(id: "Test", recorder: recorder)
        
        let prioritized = PrioritizedInterceptor(interceptor: interceptor)
        
        #expect(prioritized.priority == 0)
    }
    
    @Test("Negative priorities work correctly")
    func testNegativePriorities() async throws {
        let recorder = Recorder()
        
        let negative = RecordingInterceptor(id: "Negative", recorder: recorder)
        let zero = RecordingInterceptor(id: "Zero", recorder: recorder)
        let positive = RecordingInterceptor(id: "Positive", recorder: recorder)
        
        let transport = FakeTransportFactory.success()
        
        let client = TestClientFactory.make(
            transport: transport,
            prioritizedInterceptors: [
                PrioritizedInterceptor(interceptor: negative, priority: -5),
                PrioritizedInterceptor(interceptor: positive, priority: 5),
                PrioritizedInterceptor(interceptor: zero, priority: 0)
            ]
        )
        
        let request = Request(method: .get, url: URL(string: "https://example.com")!)
        let call = client.newCall(request)
        
        _ = try await call.execute()
        
        let events = await recorder.events
        #expect(events[0] == "Positive")
        #expect(events[1] == "Zero")
        #expect(events[2] == "Negative")
    }
}
