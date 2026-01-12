//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// Represents a cached network response.
///
/// `CacheEntry` associates a `Response` with the time it was stored,
/// allowing expiration logic to be applied.
struct CacheEntry: Sendable {

    /// The cached response.
    let response: Response

    /// The timestamp indicating when the response was cached.
    let timestamp: Date
}
