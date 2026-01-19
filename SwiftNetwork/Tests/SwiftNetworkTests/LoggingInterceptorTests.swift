//
//  LoggingInterceptorTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 19/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

// MARK: - Logging Interceptor Tests

@Suite("LoggingInterceptor with RequestBody")
struct LoggingInterceptorTests {
    
    @Test("Logging interceptor handles JSON body")
    func loggingHandlesJSONBody() async throws {
        let logger = LoggingInterceptor(level: .body)
        
        let transport = FakeTransport { request in
            TestResponses.success(request: request)
        }
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [logger]
        )
        
        struct User: Encodable, Sendable {
            let name: String
            let age: Int
        }
        
        let request = Request(
            method: .post,
            url: URL(string: "https://api.example.com/users")!,
            body: .json(User(name: "Alice", age: 30))
        )
        
        // This should not throw even though we're logging the body
        _ = try await client.newCall(request).execute()
        
        let recorded = await transport.requests
        #expect(recorded.count == 1)
    }
    
    @Test("Logging interceptor handles form body")
    func loggingHandlesFormBody() async throws {
        let logger = LoggingInterceptor(level: .body)
        
        let transport = FakeTransport { request in
            TestResponses.success(request: request)
        }
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [logger]
        )
        
        let request = Request(
            method: .post,
            url: URL(string: "https://example.com/form")!,
            body: .form(["username": "alice", "password": "secret"])
        )
        
        _ = try await client.newCall(request).execute()
        
        let recorded = await transport.requests
        #expect(recorded.count == 1)
    }
    
    @Test("Logging interceptor handles data body")
    func loggingHandlesDataBody() async throws {
        let logger = LoggingInterceptor(level: .body)
        
        let transport = FakeTransport { request in
            TestResponses.success(request: request)
        }
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [logger]
        )
        
        // Binary data that can't be decoded as UTF-8
        let binaryData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        
        let request = Request(
            method: .post,
            url: URL(string: "https://example.com/upload")!,
            body: .data(binaryData, contentType: "image/jpeg")
        )
        
        // Should handle binary data gracefully
        _ = try await client.newCall(request).execute()
        
        let recorded = await transport.requests
        #expect(recorded.count == 1)
    }
    
    @Test("Logging interceptor handles request without body")
    func loggingHandlesNoBody() async throws {
        let logger = LoggingInterceptor(level: .body)
        
        let transport = FakeTransport { request in
            TestResponses.success(request: request)
        }
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [logger]
        )
        
        let request = Request(
            method: .get,
            url: URL(string: "https://example.com/data")!
        )
        
        _ = try await client.newCall(request).execute()
        
        let recorded = await transport.requests
        #expect(recorded.count == 1)
    }
    
    @Test("Logging levels work correctly", arguments: [
        LoggingInterceptor.Level.none,
        LoggingInterceptor.Level.basic,
        LoggingInterceptor.Level.headers,
        LoggingInterceptor.Level.body
    ])
    func loggingLevelsWork(level: LoggingInterceptor.Level) async throws {
        let logger = LoggingInterceptor(level: level)
        
        let transport = FakeTransport { request in
            TestResponses.success(request: request, body: Data("response".utf8))
        }
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [logger]
        )
        
        let request = Request(
            method: .post,
            url: URL(string: "https://example.com")!,
            headers: ["X-Custom": "value"],
            body: .json(["key": "value"])
        )
        
        // Should work at all logging levels
        _ = try await client.newCall(request).execute()
        
        let recorded = await transport.requests
        #expect(recorded.count == 1)
    }
}
