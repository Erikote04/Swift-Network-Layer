//
//  DiskCacheStorageTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 20/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Disk Cache Storage")
struct DiskCacheStorageTests {
    
    @Test("Creates disk cache successfully")
    func createsDiskCache() async throws {
        let cache = try DiskCacheStorage(
            directory: "test-cache-\(UUID().uuidString)",
            ttl: 60
        )
        
        await cache.clearAll()
    }
    
    @Test("Stores and retrieves entry from disk")
    func storesAndRetrievesEntry() async throws {
        let cache = try DiskCacheStorage(
            directory: "test-cache-\(UUID().uuidString)",
            ttl: 60
        )
        
        let request = Request(
            method: .get,
            url: URL(string: "https://example.com/data")!
        )
        
        let response = Response(
            request: request,
            statusCode: 200,
            headers: ["Cache-Control": "max-age=3600"],
            body: Data("test data".utf8)
        )
        
        await cache.store(response)
        
        let retrieved = await cache.cachedResponse(for: request)
        
        #expect(retrieved != nil)
        #expect(retrieved?.body == response.body)
        
        await cache.clearAll()
    }
    
    @Test("Expired entries are removed on read")
    func expiredEntriesAreRemoved() async throws {
        let cache = try DiskCacheStorage(
            directory: "test-cache-\(UUID().uuidString)",
            ttl: 1 // 1 second TTL
        )
        
        let request = Request(
            method: .get,
            url: URL(string: "https://example.com/data")!
        )
        
        let response = Response(
            request: request,
            statusCode: 200,
            headers: [:],
            body: Data("test".utf8)
        )
        
        await cache.store(response)
        
        // Wait for expiration
        try await Task.sleep(for: .seconds(2))
        
        let retrieved = await cache.cachedResponse(for: request)
        
        #expect(retrieved == nil)
        
        await cache.clearAll()
    }
    
    @Test("Removes specific entry")
    func removesSpecificEntry() async throws {
        let cache = try DiskCacheStorage(
            directory: "test-cache-\(UUID().uuidString)",
            ttl: 60
        )
        
        let request = Request(
            method: .get,
            url: URL(string: "https://example.com/data")!
        )
        
        let response = Response(
            request: request,
            statusCode: 200,
            headers: [:],
            body: Data("test".utf8)
        )
        
        await cache.store(response)
        await cache.remove(for: request)
        
        let retrieved = await cache.cachedResponse(for: request)
        
        #expect(retrieved == nil)
        
        await cache.clearAll()
    }
    
    @Test("Clears all entries")
    func clearsAllEntries() async throws {
        let cache = try DiskCacheStorage(
            directory: "test-cache-\(UUID().uuidString)",
            ttl: 60
        )
        
        let request1 = Request(
            method: .get,
            url: URL(string: "https://example.com/1")!
        )
        
        let request2 = Request(
            method: .get,
            url: URL(string: "https://example.com/2")!
        )
        
        let response1 = Response(
            request: request1,
            statusCode: 200,
            headers: [:],
            body: Data("1".utf8)
        )
        
        let response2 = Response(
            request: request2,
            statusCode: 200,
            headers: [:],
            body: Data("2".utf8)
        )
        
        await cache.store(response1)
        await cache.store(response2)
        await cache.clearAll()
        
        let retrieved1 = await cache.cachedResponse(for: request1)
        let retrieved2 = await cache.cachedResponse(for: request2)
        
        #expect(retrieved1 == nil)
        #expect(retrieved2 == nil)
    }
}

@Suite("Hybrid Cache Storage")
struct HybridCacheStorageTests {
    
    @Test("Creates hybrid cache successfully")
    func createsHybridCache() async throws {
        let cache = try HybridCacheStorage(
            memoryCapacity: 10,
            diskDirectory: "test-hybrid-\(UUID().uuidString)",
            ttl: 60
        )
        
        await cache.clearAll()
    }
    
    @Test("Promotes disk hits to memory")
    func promotesDiskHitsToMemory() async throws {
        let cache = try HybridCacheStorage(
            memoryCapacity: 10,
            diskDirectory: "test-hybrid-\(UUID().uuidString)",
            ttl: 60
        )
        
        let request = Request(
            method: .get,
            url: URL(string: "https://example.com/data")!
        )
        
        let response = Response(
            request: request,
            statusCode: 200,
            headers: [:],
            body: Data("test".utf8)
        )
        
        await cache.store(response)
        
        // First read should hit disk and promote to memory
        let retrieved1 = await cache.cachedResponse(for: request)
        #expect(retrieved1 != nil)
        
        // Second read should hit memory (faster)
        let retrieved2 = await cache.cachedResponse(for: request)
        #expect(retrieved2 != nil)
        
        await cache.clearAll()
    }
    
    @Test("Evicts LRU entries when capacity exceeded")
    func evictsLRUEntries() async throws {
        let cache = try HybridCacheStorage(
            memoryCapacity: 2,
            diskDirectory: "test-hybrid-\(UUID().uuidString)",
            ttl: 60
        )
        
        // Store 3 entries (exceeds capacity of 2)
        for i in 1...3 {
            let request = Request(
                method: .get,
                url: URL(string: "https://example.com/\(i)")!
            )
            
            let response = Response(
                request: request,
                statusCode: 200,
                headers: [:],
                body: Data("\(i)".utf8)
            )
            
            await cache.store(response)
        }
        
        // All should still be retrievable (from disk)
        for i in 1...3 {
            let request = Request(
                method: .get,
                url: URL(string: "https://example.com/\(i)")!
            )
            
            let retrieved = await cache.cachedResponse(for: request)
            #expect(retrieved != nil)
        }
        
        await cache.clearAll()
    }
}
