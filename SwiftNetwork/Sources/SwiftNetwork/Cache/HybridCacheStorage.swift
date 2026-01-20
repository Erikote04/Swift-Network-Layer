//
//  HybridCacheStorage.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 20/1/26.
//

import Foundation

/// A hybrid cache storage that combines in-memory and disk caching.
///
/// `HybridCacheStorage` provides a two-tier caching strategy:
/// 1. **Memory cache**: Fast access for frequently used entries
/// 2. **Disk cache**: Persistent storage that survives app restarts
///
/// ## Strategy
///
/// - Reads check memory first, then disk
/// - Writes go to both memory and disk
/// - Memory cache has configurable size limit
/// - Least Recently Used (LRU) eviction from memory
///
/// ## Example Usage
///
/// ```swift
/// let hybridCache = try HybridCacheStorage(
///     memoryCapacity: 50,
///     diskDirectory: "api-cache",
///     ttl: 3600
/// )
///
/// let interceptor = CacheInterceptor(cache: hybridCache)
/// ```
public actor HybridCacheStorage: CacheStorage {
    
    private var memoryCache: [URL: (entry: CacheEntry, lastAccess: Date)] = [:]
    private let memoryCapacity: Int
    private let diskCache: DiskCacheStorage
    
    /// Creates a new hybrid cache storage.
    ///
    /// - Parameters:
    ///   - memoryCapacity: Maximum number of entries to keep in memory.
    ///   - diskDirectory: The disk cache directory name.
    ///   - ttl: Time-to-live for cached entries, in seconds.
    /// - Throws: An error if disk cache initialization fails.
    public init(
        memoryCapacity: Int = 50,
        diskDirectory: String = "swiftnetwork-cache",
        ttl: TimeInterval = 3600
    ) throws {
        self.memoryCapacity = memoryCapacity
        self.diskCache = try DiskCacheStorage(directory: diskDirectory, ttl: ttl)
    }
    
    /// Returns a cached response for a request if available and valid.
    ///
    /// - Parameter request: The request to look up.
    /// - Returns: A cached response, or `nil` if unavailable or expired.
    public func cachedResponse(for request: Request) async -> Response? {
        guard let entry = await cachedEntry(for: request) else {
            return nil
        }
        
        return entry.response
    }
    
    /// Returns a cached entry for a request if available.
    ///
    /// Checks memory first, then disk. Promotes disk hits to memory.
    ///
    /// - Parameter request: The request to look up.
    /// - Returns: A cache entry, or `nil` if unavailable.
    public func cachedEntry(for request: Request) async -> CacheEntry? {
        guard request.method == .get else {
            return nil
        }
        
        let url = request.url
        
        // Check memory cache first
        if let cached = memoryCache[url] {
            // Update last access time
            memoryCache[url] = (cached.entry, Date())
            return cached.entry
        }
        
        // Check disk cache
        if let entry = await diskCache.cachedEntry(for: request) {
            // Promote to memory
            await storeInMemory(entry, for: url)
            return entry
        }
        
        return nil
    }
    
    /// Stores a response in both memory and disk caches.
    ///
    /// - Parameter response: The response to store.
    public func store(_ response: Response) async {
        guard response.request.method == .get else {
            return
        }
        
        let entry = CacheEntry(response: response, timestamp: Date())
        
        guard !entry.shouldNotStore else {
            return
        }
        
        let url = response.request.url
        
        // Store in both caches
        await storeInMemory(entry, for: url)
        await diskCache.store(response)
    }
    
    /// Removes a cached entry from both memory and disk.
    ///
    /// - Parameter request: The request whose cache should be removed.
    public func remove(for request: Request) async {
        memoryCache.removeValue(forKey: request.url)
        await diskCache.remove(for: request)
    }
    
    /// Clears all expired entries from both memory and disk.
    public func clearExpired() async {
        // Clear expired from memory
        let now = Date()
        memoryCache = memoryCache.filter { _, value in
            !isExpired(value.entry, at: now)
        }
        
        // Clear expired from disk
        await diskCache.clearExpired()
    }
    
    /// Clears all cached entries from both memory and disk.
    public func clearAll() async {
        memoryCache.removeAll()
        await diskCache.clearAll()
    }
    
    // MARK: - Private Helpers
    
    /// Stores an entry in the memory cache with LRU eviction.
    private func storeInMemory(_ entry: CacheEntry, for url: URL) {
        // Add/update entry
        memoryCache[url] = (entry, Date())
        
        // Evict if over capacity
        if memoryCache.count > memoryCapacity {
            evictLeastRecentlyUsed()
        }
    }
    
    /// Evicts the least recently used entry from memory.
    private func evictLeastRecentlyUsed() {
        guard let lruKey = memoryCache.min(by: {
            $0.value.lastAccess < $1.value.lastAccess
        })?.key else {
            return
        }
        
        memoryCache.removeValue(forKey: lruKey)
    }
    
    /// Checks if an entry is expired at a given time.
    private func isExpired(_ entry: CacheEntry, at date: Date = Date()) -> Bool {
        if let expiresAt = entry.expiresAt {
            return date > expiresAt
        }
        
        return false
    }
}
