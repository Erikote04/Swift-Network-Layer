//
//  ConditionalInterceptorTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork on 20/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Conditional Interceptor Tests", .tags(.interceptors))
struct ConditionalInterceptorTests {
    
    // MARK: - Helpers
    
    struct RecordingRequestInterceptor: RequestInterceptor {
        let recorder: Recorder
        let name: String
        
        func interceptRequest(_ request: Request) async throws -> Request {
            await recorder.record(name)
            return request
        }
    }
    
    // MARK: - Tests
    
    @Test("Executes interceptor when host matches")
    func testHostCondition() async throws {
        let recorder = Recorder()
        let transport = FakeTransportFactory.success()
        
        let inner = RecordingRequestInterceptor(recorder: recorder, name: "Executed")
        let conditional = ConditionalInterceptor(
            interceptor: RequestResponseInterceptorAdapter(requestInterceptor: inner),
            condition: .forHost("api.example.com")
        )
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [conditional]
        )
        
        let matchingRequest = Request(method: .get, url: URL(string: "https://api.example.com/data")!)
        _ = try await client.newCall(matchingRequest).execute()
        
        let events = await recorder.events
        #expect(events.count == 1)
        #expect(events[0] == "Executed")
    }
    
    @Test("Skips interceptor when host doesn't match")
    func testHostConditionSkip() async throws {
        let recorder = Recorder()
        let transport = FakeTransportFactory.success()
        
        let inner = RecordingRequestInterceptor(recorder: recorder, name: "Executed")
        let conditional = ConditionalInterceptor(
            interceptor: RequestResponseInterceptorAdapter(requestInterceptor: inner),
            condition: .forHost("api.example.com")
        )
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [conditional]
        )
        
        let nonMatchingRequest = Request(method: .get, url: URL(string: "https://other.com/data")!)
        _ = try await client.newCall(nonMatchingRequest).execute()
        
        let events = await recorder.events
        #expect(events.isEmpty)
    }
    
    @Test("Executes interceptor when method matches")
    func testMethodCondition() async throws {
        let recorder = Recorder()
        let transport = FakeTransportFactory.success()
        
        let inner = RecordingRequestInterceptor(recorder: recorder, name: "POST")
        let conditional = ConditionalInterceptor(
            interceptor: RequestResponseInterceptorAdapter(requestInterceptor: inner),
            condition: .forMethod(.post)
        )
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [conditional]
        )
        
        let postRequest = Request(method: .post, url: URL(string: "https://example.com/data")!)
        _ = try await client.newCall(postRequest).execute()
        
        let events = await recorder.events
        #expect(events.count == 1)
        #expect(events[0] == "POST")
    }
    
    @Test("Executes interceptor when path matches")
    func testPathCondition() async throws {
        let recorder = Recorder()
        let transport = FakeTransportFactory.success()
        
        let inner = RecordingRequestInterceptor(recorder: recorder, name: "API")
        let conditional = ConditionalInterceptor(
            interceptor: RequestResponseInterceptorAdapter(requestInterceptor: inner),
            condition: .forPath("/api/")
        )
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [conditional]
        )
        
        let apiRequest = Request(method: .get, url: URL(string: "https://example.com/api/users")!)
        _ = try await client.newCall(apiRequest).execute()
        
        let events = await recorder.events
        #expect(events.count == 1)
        #expect(events[0] == "API")
    }
    
    @Test("Executes interceptor when header matches")
    func testHeaderCondition() async throws {
        let recorder = Recorder()
        let transport = FakeTransportFactory.success()
        
        let inner = RecordingRequestInterceptor(recorder: recorder, name: "Auth")
        let conditional = ConditionalInterceptor(
            interceptor: RequestResponseInterceptorAdapter(requestInterceptor: inner),
            condition: .forHeader("Authorization", value: "Bearer token")
        )
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [conditional]
        )
        
        var headers: HTTPHeaders = [:]
        headers["Authorization"] = "Bearer token"
        
        let authRequest = Request(
            method: .get,
            url: URL(string: "https://example.com/data")!,
            headers: headers
        )
        _ = try await client.newCall(authRequest).execute()
        
        let events = await recorder.events
        #expect(events.count == 1)
        #expect(events[0] == "Auth")
    }
    
    @Test("AND condition requires both conditions to pass")
    func testAndCondition() async throws {
        let recorder = Recorder()
        let transport = FakeTransportFactory.success()
        
        let inner = RecordingRequestInterceptor(recorder: recorder, name: "Both")
        let condition = ConditionalInterceptor.Condition
            .forHost("api.example.com")
            .and(.forMethod(.post))
        
        let conditional = ConditionalInterceptor(
            interceptor: RequestResponseInterceptorAdapter(requestInterceptor: inner),
            condition: condition
        )
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [conditional]
        )
        
        // Both conditions match
        let matchingRequest = Request(method: .post, url: URL(string: "https://api.example.com/data")!)
        _ = try await client.newCall(matchingRequest).execute()
        
        var events = await recorder.events
        #expect(events.count == 1)
        
        // Only one condition matches
        let partialRequest = Request(method: .get, url: URL(string: "https://api.example.com/data")!)
        _ = try await client.newCall(partialRequest).execute()
        
        events = await recorder.events
        #expect(events.count == 1) // Still 1, not executed
    }
    
    @Test("OR condition requires at least one condition to pass")
    func testOrCondition() async throws {
        let recorder = Recorder()
        let transport = FakeTransportFactory.success()
        
        let inner = RecordingRequestInterceptor(recorder: recorder, name: "Either")
        let condition = ConditionalInterceptor.Condition
            .forHost("api.example.com")
            .or(.forMethod(.post))
        
        let conditional = ConditionalInterceptor(
            interceptor: RequestResponseInterceptorAdapter(requestInterceptor: inner),
            condition: condition
        )
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [conditional]
        )
        
        // First condition matches
        let hostRequest = Request(method: .get, url: URL(string: "https://api.example.com/data")!)
        _ = try await client.newCall(hostRequest).execute()
        
        var events = await recorder.events
        #expect(events.count == 1)
        
        // Second condition matches
        let methodRequest = Request(method: .post, url: URL(string: "https://other.com/data")!)
        _ = try await client.newCall(methodRequest).execute()
        
        events = await recorder.events
        #expect(events.count == 2)
    }
    
    @Test("NOT condition inverts the result")
    func testNotCondition() async throws {
        let recorder = Recorder()
        let transport = FakeTransportFactory.success()
        
        let inner = RecordingRequestInterceptor(recorder: recorder, name: "Not API")
        let condition = ConditionalInterceptor.Condition
            .forHost("api.example.com")
            .not()
        
        let conditional = ConditionalInterceptor(
            interceptor: RequestResponseInterceptorAdapter(requestInterceptor: inner),
            condition: condition
        )
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [conditional]
        )
        
        // Should execute (not api.example.com)
        let otherRequest = Request(method: .get, url: URL(string: "https://other.com/data")!)
        _ = try await client.newCall(otherRequest).execute()
        
        var events = await recorder.events
        #expect(events.count == 1)
        
        // Should not execute (is api.example.com)
        let apiRequest = Request(method: .get, url: URL(string: "https://api.example.com/data")!)
        _ = try await client.newCall(apiRequest).execute()
        
        events = await recorder.events
        #expect(events.count == 1) // Still 1
    }
    
    @Test("Custom condition with predicate")
    func testCustomCondition() async throws {
        let recorder = Recorder()
        let transport = FakeTransportFactory.success()
        
        let inner = RecordingRequestInterceptor(recorder: recorder, name: "HTTPS")
        let condition = ConditionalInterceptor.Condition.custom { request in
            request.url.scheme == "https"
        }
        
        let conditional = ConditionalInterceptor(
            interceptor: RequestResponseInterceptorAdapter(requestInterceptor: inner),
            condition: condition
        )
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [conditional]
        )
        
        let httpsRequest = Request(method: .get, url: URL(string: "https://example.com/data")!)
        _ = try await client.newCall(httpsRequest).execute()
        
        let events = await recorder.events
        #expect(events.count == 1)
        #expect(events[0] == "HTTPS")
    }
}
