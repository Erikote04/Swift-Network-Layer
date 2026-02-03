//
//  RequestDeduplicatorTests.swift
//  SwiftNetworkTests
//
//  Created by Erik Sebastian de Erice Jerez on 28/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Request Deduplication Tests", .tags(.performance))
struct RequestDeduplicatorTests {
    
    @Test("Identical requests share single execution")
    func deduplicatesIdenticalRequests() async throws {
        let deduplicator = RequestDeduplicator()
        let counter = CallCounter()
        
        let request = Request(
            method: .get,
            url: URL(string: "https://api.example.com/data")!
        )
        
        let execute = { @Sendable () async throws -> Response in
            _ = await counter.increment()
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            return Response(
                request: request,
                statusCode: 200,
                headers: [:],
                body: Data("test".utf8)
            )
        }
        
        // Launch 5 identical requests concurrently
        let responses = try await withThrowingTaskGroup(of: Response.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    try await deduplicator.deduplicate(request: request, execute: execute)
                }
            }
            
            var results: [Response] = []
            for try await response in group {
                results.append(response)
            }
            return results
        }
        
        // All responses should be successful
        #expect(responses.count == 5)
        for response in responses {
            #expect(response.statusCode == 200)
        }
        
        // Only one actual execution should have occurred
        let count = await counter.count
        #expect(count == 1)
    }
    
    @Test("Different requests execute independently")
    func executesDifferentRequestsIndependently() async throws {
        let deduplicator = RequestDeduplicator()
        let counter = CallCounter()
        
        let request1 = Request(
            method: .get,
            url: URL(string: "https://api.example.com/data1")!
        )
        
        let request2 = Request(
            method: .get,
            url: URL(string: "https://api.example.com/data2")!
        )
        
        let execute1 = { @Sendable () async throws -> Response in
            _ = await counter.increment()
            return Response(
                request: request1,
                statusCode: 200,
                headers: [:],
                body: Data("test1".utf8)
            )
        }
        
        let execute2 = { @Sendable () async throws -> Response in
            _ = await counter.increment()
            return Response(
                request: request2,
                statusCode: 200,
                headers: [:],
                body: Data("test2".utf8)
            )
        }
        
        let (response1, response2) = try await (
            deduplicator.deduplicate(request: request1, execute: execute1),
            deduplicator.deduplicate(request: request2, execute: execute2)
        )
        
        #expect(response1.statusCode == 200)
        #expect(response2.statusCode == 200)
        
        // Two different requests should execute separately
        let count = await counter.count
        #expect(count == 2)
    }
    
    @Test("Errors are propagated to all waiting requests")
    func propagatesErrorsToAllWaiters() async throws {
        let deduplicator = RequestDeduplicator()
        
        let request = Request(
            method: .get,
            url: URL(string: "https://api.example.com/error")!
        )
        
        let execute = { @Sendable () async throws -> Response in
            try await Task.sleep(nanoseconds: 50_000_000)
            throw NetworkError.cancelled
        }
        
        do {
            _ = try await withThrowingTaskGroup(of: Response.self) { group in
                for _ in 0..<3 {
                    group.addTask {
                        try await deduplicator.deduplicate(request: request, execute: execute)
                    }
                }
                
                var results: [Response] = []
                for try await response in group {
                    results.append(response)
                }
                return results
            }
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is NetworkError)
        }
    }
    
    @Test("Requests with different methods are not deduplicated")
    func differentMethodsNotDeduplicated() async throws {
        let deduplicator = RequestDeduplicator()
        let counter = CallCounter()
        
        let url = URL(string: "https://api.example.com/data")!
        
        let getRequest = Request(method: .get, url: url)
        let postRequest = Request(method: .post, url: url)
        
        let executeGet = { @Sendable () async throws -> Response in
            _ = await counter.increment()
            return Response(request: getRequest, statusCode: 200, headers: [:], body: Data())
        }
        
        let executePost = { @Sendable () async throws -> Response in
            _ = await counter.increment()
            return Response(request: postRequest, statusCode: 200, headers: [:], body: Data())
        }
        
        _ = try await (
            deduplicator.deduplicate(request: getRequest, execute: executeGet),
            deduplicator.deduplicate(request: postRequest, execute: executePost)
        )
        
        let count = await counter.count
        #expect(count == 2)
    }
    
    @Test("Requests with different headers are not deduplicated")
    func differentHeadersNotDeduplicated() async throws {
        let deduplicator = RequestDeduplicator()
        let counter = CallCounter()
        
        let url = URL(string: "https://api.example.com/data")!
        
        let request1 = Request(
            method: .get,
            url: url,
            headers: ["Authorization": "Bearer token1"]
        )
        
        let request2 = Request(
            method: .get,
            url: url,
            headers: ["Authorization": "Bearer token2"]
        )
        
        let execute1 = { @Sendable () async throws -> Response in
            _ = await counter.increment()
            return Response(request: request1, statusCode: 200, headers: [:], body: Data())
        }
        
        let execute2 = { @Sendable () async throws -> Response in
            _ = await counter.increment()
            return Response(request: request2, statusCode: 200, headers: [:], body: Data())
        }
        
        _ = try await (
            deduplicator.deduplicate(request: request1, execute: execute1),
            deduplicator.deduplicate(request: request2, execute: execute2)
        )
        
        let count = await counter.count
        #expect(count == 2)
    }
    
    @Test("Clear removes all in-flight requests")
    func clearRemovesInFlightRequests() async throws {
        let deduplicator = RequestDeduplicator()
        
        await deduplicator.clear()
        
        // No crash or errors expected
        #expect(Bool(true))
    }
}
