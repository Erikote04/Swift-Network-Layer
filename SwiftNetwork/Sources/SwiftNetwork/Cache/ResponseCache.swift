//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public actor ResponseCache {
    private var storage: [URL: CacheEntry] = [:]
    private let ttl: TimeInterval

    public init(ttl: TimeInterval = 60) {
        self.ttl = ttl
    }

    public func cachedResponse(for request: Request) -> Response? {
        guard
            request.method == .get,
            let entry = storage[request.url],
            !isExpired(entry)
        else {
            return nil
        }

        return entry.response
    }

    public func store(_ response: Response) {
        guard response.request.method == .get else { return }

        storage[response.request.url] = CacheEntry(
            response: response,
            timestamp: Date()
        )
    }

    private func isExpired(_ entry: CacheEntry) -> Bool {
        Date().timeIntervalSince(entry.timestamp) > ttl
    }
}
