//
//  CacheControlTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 20/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Cache-Control Directives")
struct CacheControlTests {
    
    // MARK: - Directive Parsing Tests
    
    @Suite("Cache-Control Parsing")
    struct DirectiveParsingTests {
        
        @Test("Parses max-age directive")
        func parsesMaxAge() {
            let directives = CacheControlDirectives(headerValue: "max-age=3600")
            
            #expect(directives.maxAge == 3600)
            #expect(directives.noCache == false)
            #expect(directives.noStore == false)
        }
        
        @Test("Parses no-cache directive")
        func parsesNoCache() {
            let directives = CacheControlDirectives(headerValue: "no-cache")
            
            #expect(directives.noCache == true)
            #expect(directives.maxAge == nil)
        }
        
        @Test("Parses no-store directive")
        func parsesNoStore() {
            let directives = CacheControlDirectives(headerValue: "no-store")
            
            #expect(directives.noStore == true)
        }
        
        @Test("Parses must-revalidate directive")
        func parsesMustRevalidate() {
            let directives = CacheControlDirectives(headerValue: "must-revalidate")
            
            #expect(directives.mustRevalidate == true)
        }
        
        @Test("Parses public directive")
        func parsesPublic() {
            let directives = CacheControlDirectives(headerValue: "public")
            
            #expect(directives.isPublic == true)
            #expect(directives.isPrivate == false)
        }
        
        @Test("Parses private directive")
        func parsesPrivate() {
            let directives = CacheControlDirectives(headerValue: "private")
            
            #expect(directives.isPrivate == true)
            #expect(directives.isPublic == false)
        }
        
        @Test("Parses multiple directives")
        func parsesMultipleDirectives() {
            let directives = CacheControlDirectives(
                headerValue: "max-age=3600, must-revalidate, public"
            )
            
            #expect(directives.maxAge == 3600)
            #expect(directives.mustRevalidate == true)
            #expect(directives.isPublic == true)
        }
        
        @Test("Handles whitespace in header")
        func handlesWhitespace() {
            let directives = CacheControlDirectives(
                headerValue: "  max-age=1800  ,  no-cache  "
            )
            
            #expect(directives.maxAge == 1800)
            #expect(directives.noCache == true)
        }
        
        @Test("Empty header creates empty directives")
        func emptyHeaderCreatesEmptyDirectives() {
            let directives = CacheControlDirectives(headerValue: "")
            
            #expect(directives.maxAge == nil)
            #expect(directives.noCache == false)
            #expect(directives.noStore == false)
        }
    }
    
    // MARK: - Cache Entry Tests
    
    @Suite("CacheEntry with Cache-Control")
    struct CacheEntryDirectivesTests {
        
        @Test("Entry respects no-store directive")
        func entryRespectsNoStore() {
            let request = Request(method: .get, url: URL(string: "https://example.com")!)
            let response = Response(
                request: request,
                statusCode: 200,
                headers: ["Cache-Control": "no-store"],
                body: Data()
            )
            
            let entry = CacheEntry(response: response)
            
            #expect(entry.shouldNotStore == true)
        }
        
        @Test("Entry requires revalidation with no-cache")
        func entryRequiresRevalidationWithNoCache() {
            let request = Request(method: .get, url: URL(string: "https://example.com")!)
            let response = Response(
                request: request,
                statusCode: 200,
                headers: ["Cache-Control": "no-cache"],
                body: Data()
            )
            
            let entry = CacheEntry(response: response)
            
            #expect(entry.mustRevalidate == true)
        }
        
        @Test("Fresh entry with must-revalidate doesn't require revalidation")
        func freshEntryWithMustRevalidateDoesntRequireRevalidation() {
            let request = Request(method: .get, url: URL(string: "https://example.com")!)
            let response = Response(
                request: request,
                statusCode: 200,
                headers: ["Cache-Control": "max-age=3600, must-revalidate"],
                body: Data()
            )
            
            let entry = CacheEntry(response: response, timestamp: Date())
            
            #expect(entry.isExpired == false)
            #expect(entry.mustRevalidate == false)
        }
        
        @Test("Expired entry with must-revalidate requires revalidation")
        func expiredEntryWithMustRevalidateRequiresRevalidation() {
            let request = Request(method: .get, url: URL(string: "https://example.com")!)
            let response = Response(
                request: request,
                statusCode: 200,
                headers: ["Cache-Control": "max-age=1, must-revalidate"],
                body: Data()
            )
            
            let pastTimestamp = Date().addingTimeInterval(-5)
            let entry = CacheEntry(response: response, timestamp: pastTimestamp)
            
            #expect(entry.isExpired == true)
            #expect(entry.mustRevalidate == true)
        }
        
        @Test("Entry tracks public visibility")
        func entryTracksPublicVisibility() {
            let request = Request(method: .get, url: URL(string: "https://example.com")!)
            let response = Response(
                request: request,
                statusCode: 200,
                headers: ["Cache-Control": "public, max-age=3600"],
                body: Data()
            )
            
            let entry = CacheEntry(response: response)
            
            #expect(entry.isPublic == true)
        }
        
        @Test("Entry tracks private visibility")
        func entryTracksPrivateVisibility() {
            let request = Request(method: .get, url: URL(string: "https://example.com")!)
            let response = Response(
                request: request,
                statusCode: 200,
                headers: ["Cache-Control": "private, max-age=1800"],
                body: Data()
            )
            
            let entry = CacheEntry(response: response)
            
            #expect(entry.isPublic == false)
        }
    }
    
    // MARK: - Interceptor Tests
    
    @Suite("CacheInterceptor with Cache-Control")
    struct InterceptorDirectivesTests {
        
        @Test("Interceptor doesn't cache no-store responses")
        func interceptorDoesntCacheNoStore() async throws {
            let cache = ResponseCache(ttl: 60)
            let interceptor = CacheInterceptor(cache: cache)
            
            let request = Request(
                method: .get,
                url: URL(string: "https://example.com/secret")!,
                cachePolicy: .respectHeaders
            )
            
            let chain = FakeChain(request: request) { _ in
                Response(
                    request: request,
                    statusCode: 200,
                    headers: ["Cache-Control": "no-store"],
                    body: Data("secret data".utf8)
                )
            }
            
            _ = try await interceptor.intercept(chain)
            
            // Should not be cached
            let cached = await cache.cachedEntry(for: request)
            #expect(cached == nil)
        }
        
        @Test("Interceptor revalidates no-cache responses")
        func interceptorRevalidatesNoCache() async throws {
            let cache = ResponseCache(ttl: 60)
            let interceptor = CacheInterceptor(cache: cache)
            
            let request = Request(
                method: .get,
                url: URL(string: "https://example.com/data")!,
                cachePolicy: .respectHeaders
            )
            
            // Store a cached entry with no-cache
            let cachedResponse = Response(
                request: request,
                statusCode: 200,
                headers: [
                    "Cache-Control": "no-cache",
                    "ETag": "\"v1\""
                ],
                body: Data("cached".utf8)
            )
            await cache.store(cachedResponse)
            
            let spy = CallSpy()
            
            let chain = FakeChain(request: request) { conditionalRequest in
                await spy.capture(headers: conditionalRequest.headers)
                
                // Return 304 Not Modified
                return Response(
                    request: conditionalRequest,
                    statusCode: 304,
                    headers: [:],
                    body: nil
                )
            }
            
            let response = try await interceptor.intercept(chain)
            
            // Should have made conditional request
            let headers = await spy.receivedHeaders
            #expect(headers?["If-None-Match"] == "\"v1\"")
            
            // Should return cached body
            #expect(response.body == Data("cached".utf8))
        }
        
        @Test("Interceptor uses fresh cached response with max-age")
        func interceptorUsesFreshCachedResponse() async throws {
            let cache = ResponseCache(ttl: 60)
            let interceptor = CacheInterceptor(cache: cache)
            
            let request = Request(
                method: .get,
                url: URL(string: "https://example.com/data")!,
                cachePolicy: .respectHeaders
            )
            
            // Store fresh response
            let cachedResponse = Response(
                request: request,
                statusCode: 200,
                headers: ["Cache-Control": "max-age=3600"],
                body: Data("fresh".utf8)
            )
            await cache.store(cachedResponse)
            
            let spy = CallSpy()
            
            let chain = FakeChain(request: request) { _ in
                await spy.markCalled()
                throw NetworkError.invalidResponse
            }
            
            let response = try await interceptor.intercept(chain)
            
            // Should NOT have called network
            #expect(await spy.wasCalled == false)
            #expect(response.body == Data("fresh".utf8))
        }
        
        @Test("Interceptor revalidates expired must-revalidate entry")
        func interceptorRevalidatesExpiredMustRevalidate() async throws {
            let cache = TestableResponseCache()
            let interceptor = CacheInterceptor(cache: cache)
            
            let request = Request(
                method: .get,
                url: URL(string: "https://example.com/data")!,
                cachePolicy: .respectHeaders
            )
            
            // Create expired entry manually
            let expiredResponse = Response(
                request: request,
                statusCode: 200,
                headers: [
                    "Cache-Control": "max-age=1, must-revalidate",
                    "ETag": "\"old\""
                ],
                body: Data("stale".utf8)
            )
            
            let expiredEntry = CacheEntry(
                response: expiredResponse,
                timestamp: Date().addingTimeInterval(-10)
            )
            
            await cache.forceStoreEntry(expiredEntry, for: request)
            
            let spy = CallSpy()
            
            let chain = FakeChain(request: request) { conditionalRequest in
                await spy.capture(headers: conditionalRequest.headers)
                
                // Return new data
                return Response(
                    request: conditionalRequest,
                    statusCode: 200,
                    headers: ["ETag": "\"new\""],
                    body: Data("fresh".utf8)
                )
            }
            
            let response = try await interceptor.intercept(chain)
            
            // Should have revalidated
            let headers = await spy.receivedHeaders
            #expect(headers?["If-None-Match"] == "\"old\"")
            
            // Should return fresh data
            #expect(response.body == Data("fresh".utf8))
        }
    }
}

// MARK: - Test Utilities

private actor CallSpy {
    private(set) var wasCalled = false
    private(set) var receivedHeaders: HTTPHeaders?

    func markCalled() {
        wasCalled = true
    }

    func capture(headers: HTTPHeaders) {
        receivedHeaders = headers
    }
}

private struct FakeChain: InterceptorChainProtocol {
    let request: Request
    let handler: @Sendable (Request) async throws -> Response

    func proceed(_ request: Request) async throws -> Response {
        try await handler(request)
    }
}

/// A testable wrapper that implements CacheStorage for testing.
private actor TestableResponseCache: CacheStorage {
    private var storage: [URL: CacheEntry] = [:]
    private let ttl: TimeInterval
    
    init(ttl: TimeInterval = 60) {
        self.ttl = ttl
    }
    
    func cachedResponse(for request: Request) async -> Response? {
        guard
            request.method == .get,
            let entry = storage[request.url],
            !isExpired(entry)
        else {
            return nil
        }
        
        return entry.response
    }
    
    func cachedEntry(for request: Request) async -> CacheEntry? {
        guard request.method == .get else {
            return nil
        }
        
        return storage[request.url]
    }
    
    func store(_ response: Response) async {
        guard response.request.method == .get else { return }
        
        let entry = CacheEntry(response: response, timestamp: Date())
        
        guard !entry.shouldNotStore else { return }
        
        storage[response.request.url] = entry
    }
    
    func forceStoreEntry(_ entry: CacheEntry, for request: Request) {
        storage[request.url] = entry
    }
    
    func remove(for request: Request) async {
        storage.removeValue(forKey: request.url)
    }
    
    private func isExpired(_ entry: CacheEntry) -> Bool {
        if entry.expiresAt != nil {
            return entry.isExpired
        }
        
        return Date().timeIntervalSince(entry.timestamp) > ttl
    }
}
