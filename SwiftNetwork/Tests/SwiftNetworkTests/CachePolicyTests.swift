//
//  CachePolicyTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 19/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Cache Policy", .tags(.cache))
struct CachePolicyTests {

    // MARK: - CacheEntry Tests

    @Suite("CacheEntry Metadata")
    struct CacheEntryMetadataTests {

        @Test("Extracts ETag from response headers")
        func extractsETag() {
            let request = Request(method: .get, url: URL(string: "https://example.com")!)
            let response = Response(
                request: request,
                statusCode: 200,
                headers: ["ETag": "\"123abc\""],
                body: Data()
            )

            let entry = CacheEntry(response: response)

            #expect(entry.etag == "\"123abc\"")
        }

        @Test("Extracts Last-Modified from response headers")
        func extractsLastModified() {
            let request = Request(method: .get, url: URL(string: "https://example.com")!)
            let response = Response(
                request: request,
                statusCode: 200,
                headers: ["Last-Modified": "Mon, 15 Jan 2024 12:00:00 GMT"],
                body: Data()
            )

            let entry = CacheEntry(response: response)

            #expect(entry.lastModified == "Mon, 15 Jan 2024 12:00:00 GMT")
        }

        @Test("Calculates expiration from max-age")
        func calculatesExpirationFromMaxAge() {
            let request = Request(method: .get, url: URL(string: "https://example.com")!)
            let response = Response(
                request: request,
                statusCode: 200,
                headers: ["Cache-Control": "max-age=3600"],
                body: Data()
            )

            let timestamp = Date()
            let entry = CacheEntry(response: response, timestamp: timestamp)

            #expect(entry.expiresAt != nil)

            if let expiresAt = entry.expiresAt {
                let diff = expiresAt.timeIntervalSince(timestamp)
                #expect(abs(diff - 3600) < 1)
            }
        }

        @Test("Detects expired entries")
        func detectsExpiredEntries() {
            let request = Request(method: .get, url: URL(string: "https://example.com")!)
            let response = Response(
                request: request,
                statusCode: 200,
                headers: ["Cache-Control": "max-age=1"],
                body: Data()
            )

            let pastTimestamp = Date().addingTimeInterval(-5)
            let entry = CacheEntry(response: response, timestamp: pastTimestamp)

            #expect(entry.isExpired == true)
        }

        @Test("Non-expired entries return false")
        func nonExpiredEntriesReturnFalse() {
            let request = Request(method: .get, url: URL(string: "https://example.com")!)
            let response = Response(
                request: request,
                statusCode: 200,
                headers: ["Cache-Control": "max-age=3600"],
                body: Data()
            )

            let entry = CacheEntry(response: response, timestamp: Date())

            #expect(entry.isExpired == false)
        }
    }

    // MARK: - Cache Policy Behaviors

    @Suite("Cache Policy Behaviors")
    struct CachePolicyBehaviorTests {

        @Test("useCache returns cached response without network call")
        func useCacheReturnsCachedResponse() async throws {
            let cache = ResponseCache(ttl: 60)
            let interceptor = CacheInterceptor(cache: cache)

            let request = Request(
                method: .get,
                url: URL(string: "https://example.com/data")!,
                cachePolicy: .useCache
            )

            let cachedResponse = Response(
                request: request,
                statusCode: 200,
                headers: [:],
                body: Data("cached".utf8)
            )

            await cache.store(cachedResponse)

            let spy = CallSpy()

            let chain = FakeChain(request: request) { _ in
                await spy.markCalled()
                throw NetworkError.invalidResponse
            }

            let response = try await interceptor.intercept(chain)

            #expect(await spy.wasCalled == false)
            #expect(response.body == Data("cached".utf8))
        }

        @Test("ignoreCache always performs network request")
        func ignoreCacheAlwaysPerformsNetworkRequest() async throws {
            let cache = ResponseCache(ttl: 60)
            let interceptor = CacheInterceptor(cache: cache)

            let request = Request(
                method: .get,
                url: URL(string: "https://example.com/data")!,
                cachePolicy: .ignoreCache
            )

            let cachedResponse = Response(
                request: request,
                statusCode: 200,
                headers: [:],
                body: Data("cached".utf8)
            )

            await cache.store(cachedResponse)

            let spy = CallSpy()

            let chain = FakeChain(request: request) { _ in
                await spy.markCalled()
                return Response(
                    request: request,
                    statusCode: 200,
                    headers: [:],
                    body: Data("fresh".utf8)
                )
            }

            let response = try await interceptor.intercept(chain)

            #expect(await spy.wasCalled == true)
            #expect(response.body == Data("fresh".utf8))
        }

        @Test("revalidate sends conditional request with ETag")
        func revalidateSendsConditionalRequestWithETag() async throws {
            let cache = ResponseCache(ttl: 60)
            let interceptor = CacheInterceptor(cache: cache)

            let request = Request(
                method: .get,
                url: URL(string: "https://example.com/data")!,
                cachePolicy: .revalidate
            )

            let cachedResponse = Response(
                request: request,
                statusCode: 200,
                headers: ["ETag": "\"abc123\""],
                body: Data("cached".utf8)
            )

            await cache.store(cachedResponse)

            let spy = CallSpy()

            let chain = FakeChain(request: request) { conditionalRequest in
                await spy.capture(headers: conditionalRequest.headers)

                return Response(
                    request: conditionalRequest,
                    statusCode: 304,
                    headers: [:],
                    body: nil
                )
            }

            let response = try await interceptor.intercept(chain)

            #expect(await spy.receivedHeaders?["If-None-Match"] == "\"abc123\"")
            #expect(response.body == Data("cached".utf8))
        }

        @Test("respectHeaders follows max-age directive")
        func respectHeadersFollowsMaxAge() async throws {
            let cache = ResponseCache(ttl: 1)
            let interceptor = CacheInterceptor(cache: cache)

            let request = Request(
                method: .get,
                url: URL(string: "https://example.com/data")!,
                cachePolicy: .respectHeaders
            )

            let cachedResponse = Response(
                request: request,
                statusCode: 200,
                headers: ["Cache-Control": "max-age=1"],
                body: Data("cached".utf8)
            )

            await cache.store(cachedResponse)

            try await Task.sleep(for: .seconds(2))

            let spy = CallSpy()

            let chain = FakeChain(request: request) { _ in
                await spy.markCalled()
                return Response(
                    request: request,
                    statusCode: 200,
                    headers: [:],
                    body: Data("fresh".utf8)
                )
            }

            _ = try await interceptor.intercept(chain)

            #expect(await spy.wasCalled == true)
        }

        @Test("respectHeaders obeys no-store directive")
        func respectHeadersObeysNoStore() async throws {
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
                    body: Data("secret".utf8)
                )
            }

            let response = try await interceptor.intercept(chain)

            #expect(response.body == Data("secret".utf8))

            let cachedResponse = await cache.cachedResponse(for: request)
            #expect(cachedResponse == nil)
        }
    }

    // MARK: - Parameterized Tests

    @Suite("Cache Policy Parameterized")
    struct CachePolicyParameterizedTests {

        @Test(
            "All policies handle successful responses",
            arguments: [
                CachePolicy.useCache,
                CachePolicy.ignoreCache,
                CachePolicy.revalidate,
                CachePolicy.respectHeaders
            ]
        )
        func allPoliciesHandleSuccessfulResponses(policy: CachePolicy) async throws {
            let cache = ResponseCache(ttl: 60)
            let interceptor = CacheInterceptor(cache: cache)

            let request = Request(
                method: .get,
                url: URL(string: "https://example.com/test")!,
                cachePolicy: policy
            )

            let chain = FakeChain(request: request) { _ in
                Response(
                    request: request,
                    statusCode: 200,
                    headers: [:],
                    body: Data("success".utf8)
                )
            }

            let response = try await interceptor.intercept(chain)

            #expect(response.statusCode == 200)
            #expect(response.body == Data("success".utf8))
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
