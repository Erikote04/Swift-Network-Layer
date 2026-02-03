//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 8/1/26.
//

import Testing
@testable import SwiftNetwork

@Suite("Cache Interceptor Tests", .tags(.cache))
struct CacheInterceptorTests {
    
    @Test
    func cachedResponseIsReturnedWithoutCallingTransport() async throws {
        let cache = ResponseCache(ttl: 60)
        
        let request = Request(
            method: .get,
            url: URL(string: "https://example.com")!
        )
        
        let cachedResponse = Response(
            request: request,
            statusCode: 200,
            headers: [:],
            body: Data("cached".utf8)
        )
        
        await cache.store(cachedResponse)
        
        let interceptor = CacheInterceptor(cache: cache)
        
        let transport = FakeCountingTransport(
            response: Response(
                request: request,
                statusCode: 200,
                headers: [:],
                body: Data("network".utf8)
            )
        )
        
        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [interceptor]
        )
        
        let response = try await client
            .newCall(request)
            .execute()
        
        #expect(response.body == cachedResponse.body)
        #expect(await transport.calls == 0)
    }
    
    @Test
    func responseIsCachedOnMiss() async throws {
        let cache = ResponseCache(ttl: 60)

        let request = Request(
            method: .get,
            url: URL(string: "https://example.com")!
        )

        let networkResponse = Response(
            request: request,
            statusCode: 200,
            headers: [:],
            body: Data("network".utf8)
        )

        let interceptor = CacheInterceptor(cache: cache)
        let transport = FakeCountingTransport(response: networkResponse)

        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [interceptor]
        )

        _ = try await client
            .newCall(request)
            .execute()

        let cached = await cache.cachedResponse(for: request)

        #expect(await transport.calls == 1)
        #expect(cached?.body == networkResponse.body)
    }
    
    @Test
    func errorResponsesAreNotCached() async throws {
        let cache = ResponseCache(ttl: 60)

        let request = Request(
            method: .get,
            url: URL(string: "https://example.com")!
        )

        let errorResponse = Response(
            request: request,
            statusCode: 500,
            headers: [:],
            body: Data()
        )

        let interceptor = CacheInterceptor(cache: cache)
        let transport = FakeCountingTransport(response: errorResponse)

        let client = TestClientFactory.make(
            transport: transport,
            interceptors: [interceptor]
        )

        _ = try await client
            .newCall(request)
            .execute()

        let cached = await cache.cachedResponse(for: request)

        #expect(cached == nil)
    }
}
