//
//  CacheControlDirectives.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//


/// Represents parsed Cache-Control header directives.
///
/// Provides structured access to standard HTTP caching directives
/// as defined in RFC 7234.
struct CacheControlDirectives: Sendable {
    
    /// Maximum age in seconds before the response becomes stale.
    let maxAge: Int?
    
    /// Requires revalidation with the origin server before using cached response.
    let noCache: Bool
    
    /// Response must not be stored in any cache.
    let noStore: Bool
    
    /// Must revalidate stale responses before use.
    let mustRevalidate: Bool
    
    /// Indicates the response is suitable for shared caches.
    let isPublic: Bool
    
    /// Indicates the response is intended for a single user.
    let isPrivate: Bool
    
    /// Creates cache control directives by parsing a Cache-Control header value.
    ///
    /// - Parameter headerValue: The Cache-Control header string to parse.
    init(headerValue: String) {
        let directives = headerValue
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        
        var maxAge: Int?
        var noCache = false
        var noStore = false
        var mustRevalidate = false
        var isPublic = false
        var isPrivate = false
        
        for directive in directives {
            if directive.hasPrefix("max-age=") {
                let value = directive.dropFirst("max-age=".count)
                maxAge = Int(value)
            } else if directive == "no-cache" {
                noCache = true
            } else if directive == "no-store" {
                noStore = true
            } else if directive == "must-revalidate" {
                mustRevalidate = true
            } else if directive == "public" {
                isPublic = true
            } else if directive == "private" {
                isPrivate = true
            }
        }
        
        self.maxAge = maxAge
        self.noCache = noCache
        self.noStore = noStore
        self.mustRevalidate = mustRevalidate
        self.isPublic = isPublic
        self.isPrivate = isPrivate
    }
    
    /// Creates empty cache control directives (no directives present).
    init() {
        self.maxAge = nil
        self.noCache = false
        self.noStore = false
        self.mustRevalidate = false
        self.isPublic = false
        self.isPrivate = false
    }
}