//
//  CacheInterceptorMetricsTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork on 21/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Cache Interceptor Metrics Tests")
struct CacheInterceptorMetricsTests {
    
    @Test("CacheInterceptor records cache hits")
    func testCacheHitRecording() async throws {
        let storage = InMemoryCacheStorage()
        let recorder = MetricsRecorder()
        let interceptor = CacheInterceptor(
            cache: storage,
            metrics: recorder
        )
        
        let transport = FakeTransport { request in
            Response(
                request: request,
                statusCode: 200,
                headers: [:],
                body: Data("test".utf8)
            )
        }
        
        let client = NetworkClient(
            transport: transport,
            interceptors: [interceptor]
        )
        
        let url = URL(string: "https://api.example.com/data")!
        
        let request = Request(
            method: .get,
            url: url,
            cachePolicy: .useCache
        )
        
        // First call - cache miss
        _ = try await client.newCall(request).execute()
        
        // Second call - cache hit (same URL and policy)
        let secondRequest = Request(
            method: .get,
            url: url,
            cachePolicy: .useCache
        )
        _ = try await client.newCall(secondRequest).execute()
        
        let cacheEvents = await recorder.cacheEvents
        #expect(cacheEvents.count == 2)
        #expect(cacheEvents[0].result == .miss)
        #expect(cacheEvents[1].result == .hit)
    }
    
    @Test("CacheInterceptor records revalidation")
    func testRevalidationRecording() async throws {
        let storage = InMemoryCacheStorage()
        let recorder = MetricsRecorder()
        let interceptor = CacheInterceptor(
            cache: storage,
            metrics: recorder
        )
        
        let counter = CallCounter()
        let transport = FakeTransport { request in
            let count = await counter.increment()
            if count == 1 {
                return Response(
                    request: request,
                    statusCode: 200,
                    headers: ["ETag": "abc123"],
                    body: Data("initial".utf8)
                )
            } else {
                // Return 304 Not Modified
                return Response(
                    request: request,
                    statusCode: 304,
                    headers: [:],
                    body: nil
                )
            }
        }
        
        let client = NetworkClient(
            transport: transport,
            interceptors: [interceptor]
        )
        
        let url = URL(string: "https://api.example.com/data")!
        
        // First call - cache miss, stores response with ETag
        let firstRequest = Request(
            method: .get,
            url: url,
            cachePolicy: .useCache
        )
        _ = try await client.newCall(firstRequest).execute()
        
        // Second call with revalidate policy - should trigger 304
        let revalidateRequest = Request(
            method: .get,
            url: url,
            cachePolicy: .revalidate
        )
        _ = try await client.newCall(revalidateRequest).execute()
        
        let cacheEvents = await recorder.cacheEvents
        #expect(cacheEvents.count == 2)
        #expect(cacheEvents[0].result == .miss)
        #expect(cacheEvents[1].result == .revalidated)
    }
    
    @Test("CacheInterceptor records cache miss on ignoreCache policy")
    func testIgnoreCacheRecording() async throws {
        let storage = InMemoryCacheStorage()
        let recorder = MetricsRecorder()
        let interceptor = CacheInterceptor(
            cache: storage,
            metrics: recorder
        )
        
        let transport = FakeTransport { request in
            Response(
                request: request,
                statusCode: 200,
                headers: [:],
                body: Data("test".utf8)
            )
        }
        
        let client = NetworkClient(
            transport: transport,
            interceptors: [interceptor]
        )
        
        let url = URL(string: "https://api.example.com/data")!
        
        // First call to populate cache
        let firstRequest = Request(
            method: .get,
            url: url,
            cachePolicy: .useCache
        )
        _ = try await client.newCall(firstRequest).execute()
        
        // Second call with ignoreCache - should be a miss
        let ignoreCacheRequest = Request(
            method: .get,
            url: url,
            cachePolicy: .ignoreCache
        )
        _ = try await client.newCall(ignoreCacheRequest).execute()
        
        let cacheEvents = await recorder.cacheEvents
        #expect(cacheEvents.count == 2)
        #expect(cacheEvents[0].result == .miss)
        #expect(cacheEvents[1].result == .miss)
    }
}

actor InMemoryCacheStorage: CacheStorage {
    private var storage: [String: CacheEntry] = [:]
    
    func get(_ key: String) -> CacheEntry? {
        storage[key]
    }
    
    func set(_ key: String, value: CacheEntry) {
        storage[key] = value
    }
    
    func clear() {
        storage.removeAll()
    }
    
    func cachedResponse(for request: Request) -> Response? {
        let key = cacheKey(for: request)
        guard let entry = storage[key] else { return nil }
        return entry.response
    }
    
    func cachedEntry(for request: Request) -> CacheEntry? {
        let key = cacheKey(for: request)
        return storage[key]
    }
    
    func store(_ response: Response) {
        let key = cacheKey(for: response.request)
        let entry = CacheEntry(response: response)
        storage[key] = entry
    }
    
    func remove(for request: Request) {
        let key = cacheKey(for: request)
        storage.removeValue(forKey: key)
    }
    
    private func cacheKey(for request: Request) -> String {
        "\(request.method.rawValue):\(request.url.absoluteString)"
    }
}
