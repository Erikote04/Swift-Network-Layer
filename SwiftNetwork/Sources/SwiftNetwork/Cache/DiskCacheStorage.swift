//
//  DiskCacheStorage.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 20/1/26.
//

import Foundation

/// A disk-based implementation of cache storage.
///
/// `DiskCacheStorage` persists cached responses to disk, allowing cache
/// to survive app restarts. It uses the file system to store cache entries
/// with automatic cleanup of expired entries.
///
/// ## Storage Location
///
/// Cache files are stored in the app's caches directory:
/// - iOS/macOS: `Library/Caches/com.swiftnetwork.cache/`
///
/// ## Cleanup Strategy
///
/// - Expired entries are removed on read
/// - Automatic cleanup runs periodically
/// - Manual cleanup can be triggered via `clearExpired()`
///
/// ## Example Usage
///
/// ```swift
/// let diskCache = try DiskCacheStorage(
///     directory: "api-cache",
///     ttl: 3600 // 1 hour
/// )
///
/// let interceptor = CacheInterceptor(cache: diskCache)
/// ```
public actor DiskCacheStorage: CacheStorage {
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let ttl: TimeInterval
    
    /// Creates a new disk-based cache storage.
    ///
    /// - Parameters:
    ///   - directory: The subdirectory name within the caches folder.
    ///   - ttl: Time-to-live for cached entries, in seconds. Defaults to 3600 (1 hour).
    /// - Throws: An error if the cache directory cannot be created.
    public init(directory: String = "swiftnetwork-cache", ttl: TimeInterval = 3600) throws {
        self.ttl = ttl
        
        // Get caches directory
        guard let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw CacheStorageError.unableToCreateDirectory
        }
        
        self.cacheDirectory = cachesURL.appendingPathComponent(directory, isDirectory: true)
        
        // Create directory if needed (synchronously in init)
        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try FileManager.default.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true
            )
        }
        
        // Schedule periodic cleanup
        Task {
            await schedulePeriodicCleanup()
        }
    }
    
    /// Returns a cached response for a request if available and valid.
    ///
    /// - Parameter request: The request to look up.
    /// - Returns: A cached response, or `nil` if unavailable or expired.
    public func cachedResponse(for request: Request) async -> Response? {
        guard let entry = await cachedEntry(for: request),
              !isExpired(entry) else {
            return nil
        }
        
        return entry.response
    }
    
    /// Returns a cached entry for a request if available.
    ///
    /// - Parameter request: The request to look up.
    /// - Returns: A cache entry, or `nil` if unavailable.
    public func cachedEntry(for request: Request) async -> CacheEntry? {
        guard request.method == .get else {
            return nil
        }
        
        let fileURL = cacheFileURL(for: request)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let storedEntry = try decoder.decode(StoredCacheEntry.self, from: data)
            
            let entry = storedEntry.toCacheEntry()
            
            // Clean up if expired
            if isExpired(entry) {
                try? fileManager.removeItem(at: fileURL)
                return nil
            }
            
            return entry
        } catch {
            // Corrupted file - remove it
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
    }
    
    /// Stores a response in the cache.
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
        
        let fileURL = cacheFileURL(for: response.request)
        let storedEntry = StoredCacheEntry(from: entry)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(storedEntry)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Failed to write - silently ignore
        }
    }
    
    /// Removes a cached entry for a request.
    ///
    /// - Parameter request: The request whose cache should be removed.
    public func remove(for request: Request) async {
        let fileURL = cacheFileURL(for: request)
        try? fileManager.removeItem(at: fileURL)
    }
    
    /// Clears all expired entries from disk.
    ///
    /// This method can be called manually to force cleanup.
    public func clearExpired() async {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return
        }
        
        for fileURL in files {
            guard let data = try? Data(contentsOf: fileURL),
                  let storedEntry = try? JSONDecoder().decode(StoredCacheEntry.self, from: data) else {
                continue
            }
            
            let entry = storedEntry.toCacheEntry()
            
            if isExpired(entry) {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    /// Clears all cached entries.
    public func clearAll() async {
        try? fileManager.removeItem(at: cacheDirectory)
        
        // Recreate directory
        try? fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }
    
    // MARK: - Private Helpers
    
    /// Generates a file URL for a given request.
    private func cacheFileURL(for request: Request) -> URL {
        let key = cacheKey(for: request)
        return cacheDirectory.appendingPathComponent(key)
    }
    
    /// Generates a cache key from a request.
    private func cacheKey(for request: Request) -> String {
        let urlString = request.url.absoluteString
        return urlString.sha256Hash()
    }
    
    /// Checks if a cache entry is expired.
    private func isExpired(_ entry: CacheEntry) -> Bool {
        if entry.expiresAt != nil {
            return entry.isExpired
        }
        
        return Date().timeIntervalSince(entry.timestamp) > ttl
    }
    
    /// Schedules periodic cleanup of expired entries.
    private func schedulePeriodicCleanup() async {
        while true {
            try? await Task.sleep(for: .seconds(300)) // Every 5 minutes
            await clearExpired()
        }
    }
}
