//
//  CacheEntry.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// Represents a cached network response.
///
/// `CacheEntry` associates a `Response` with caching metadata including
/// storage time, expiration, ETags, and last-modified dates for proper
/// HTTP cache semantics.
struct CacheEntry: Sendable {

    /// The cached response.
    let response: Response

    /// The timestamp indicating when the response was cached.
    let timestamp: Date
    
    /// The ETag value from the response, if present.
    ///
    /// Used for conditional requests with `If-None-Match` header.
    let etag: String?
    
    /// The Last-Modified date from the response, if present.
    ///
    /// Used for conditional requests with `If-Modified-Since` header.
    let lastModified: String?
    
    /// The expiration date calculated from Cache-Control or Expires headers.
    ///
    /// If `nil`, the entry doesn't have explicit expiration information.
    let expiresAt: Date?
    
    /// Creates a cache entry from a response.
    ///
    /// Automatically extracts caching metadata from response headers.
    ///
    /// - Parameters:
    ///   - response: The response to cache.
    ///   - timestamp: The time when the response was received. Defaults to now.
    init(response: Response, timestamp: Date = Date()) {
        self.response = response
        self.timestamp = timestamp
        self.etag = response.headers["ETag"]
        self.lastModified = response.headers["Last-Modified"]
        self.expiresAt = Self.calculateExpiration(from: response, timestamp: timestamp)
    }
    
    /// Checks if the cache entry is expired.
    ///
    /// - Returns: `true` if the entry has an expiration date and it has passed.
    var isExpired: Bool {
        guard let expiresAt = expiresAt else {
            return false
        }
        return Date() > expiresAt
    }
    
    /// The age of the cache entry in seconds.
    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
    
    // MARK: - Private Helpers
    
    /// Calculates the expiration date from response headers.
    ///
    /// Priority:
    /// 1. Cache-Control: max-age
    /// 2. Expires header
    /// 3. No expiration (returns nil)
    ///
    /// - Parameters:
    ///   - response: The response to extract headers from.
    ///   - timestamp: The time the response was received.
    /// - Returns: The expiration date, or `nil` if no expiration is specified.
    private static func calculateExpiration(from response: Response, timestamp: Date) -> Date? {
        // Check Cache-Control: max-age
        if let cacheControl = response.headers["Cache-Control"] {
            if let maxAge = extractMaxAge(from: cacheControl) {
                return timestamp.addingTimeInterval(TimeInterval(maxAge))
            }
        }
        
        // Check Expires header
        if let expiresString = response.headers["Expires"],
           let expiresDate = parseHTTPDate(expiresString) {
            return expiresDate
        }
        
        return nil
    }
    
    /// Extracts max-age value from Cache-Control header.
    ///
    /// - Parameter cacheControl: The Cache-Control header value.
    /// - Returns: The max-age in seconds, or `nil` if not present.
    private static func extractMaxAge(from cacheControl: String) -> Int? {
        let directives = cacheControl.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        for directive in directives {
            if directive.lowercased().hasPrefix("max-age=") {
                let value = directive.dropFirst("max-age=".count)
                return Int(value)
            }
        }
        
        return nil
    }
    
    /// Parses an HTTP date string (RFC 2822 or RFC 1123 format).
    ///
    /// - Parameter dateString: The date string to parse.
    /// - Returns: The parsed date, or `nil` if parsing fails.
    private static func parseHTTPDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        
        // Try RFC 1123 format (preferred)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try RFC 850 format
        formatter.dateFormat = "EEEE, dd-MMM-yy HH:mm:ss zzz"
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try ANSI C's asctime() format
        formatter.dateFormat = "EEE MMM d HH:mm:ss yyyy"
        return formatter.date(from: dateString)
    }
}
