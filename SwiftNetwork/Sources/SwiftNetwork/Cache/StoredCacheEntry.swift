//
//  StoredCacheEntry.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Foundation

/// A serializable representation of a cache entry.
struct StoredCacheEntry: Codable {
    let url: String
    let method: String
    let statusCode: Int
    let headers: [String: String]
    let body: Data?
    let timestamp: Date
    let etag: String?
    let lastModified: String?
    let expiresAt: Date?
    let cacheControl: StoredCacheControlDirectives
    
    init(from entry: CacheEntry) {
        self.url = entry.response.request.url.absoluteString
        self.method = entry.response.request.method.rawValue
        self.statusCode = entry.response.statusCode
        self.headers = entry.response.headers.all
        self.body = entry.response.body
        self.timestamp = entry.timestamp
        self.etag = entry.etag
        self.lastModified = entry.lastModified
        self.expiresAt = entry.expiresAt
        self.cacheControl = StoredCacheControlDirectives(from: entry.cacheControl)
    }
    
    func toCacheEntry() -> CacheEntry {
        let request = Request(
            method: HTTPMethod(rawValue: method) ?? .get,
            url: URL(string: url)!,
            headers: HTTPHeaders(headers)
        )
        
        let response = Response(
            request: request,
            statusCode: statusCode,
            headers: HTTPHeaders(headers),
            body: body
        )
        
        return CacheEntry(response: response, timestamp: timestamp)
    }
}
