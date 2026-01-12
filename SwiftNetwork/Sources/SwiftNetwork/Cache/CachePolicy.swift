//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// Defines caching behavior for a request.
///
/// `CachePolicy` determines whether a request should use cached responses
/// or always fetch fresh data from the network.
public enum CachePolicy: Sendable {

    /// Use a cached response if available and valid.
    case useCache

    /// Ignore cached responses and always perform a network request.
    case reloadIgnoringCache
}
