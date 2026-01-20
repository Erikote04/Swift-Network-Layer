//
//  StoredCacheControlDirectives.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Foundation

/// A serializable representation of cache control directives.
struct StoredCacheControlDirectives: Codable {
    let maxAge: Int?
    let noCache: Bool
    let noStore: Bool
    let mustRevalidate: Bool
    let isPublic: Bool
    let isPrivate: Bool
    
    init(from directives: CacheControlDirectives) {
        self.maxAge = directives.maxAge
        self.noCache = directives.noCache
        self.noStore = directives.noStore
        self.mustRevalidate = directives.mustRevalidate
        self.isPublic = directives.isPublic
        self.isPrivate = directives.isPrivate
    }
}
