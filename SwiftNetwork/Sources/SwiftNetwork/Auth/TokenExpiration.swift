//
//  TokenExpiration.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Foundation

/// Tracks token expiration timing.
///
/// `TokenExpiration` calculates whether a token has expired based on
/// its issuance time and expiration duration.
public struct TokenExpiration: Sendable, Equatable {
    
    /// The date when the token was issued.
    public let issuedAt: Date
    
    /// The duration in seconds until the token expires.
    public let expiresIn: TimeInterval
    
    /// The calculated expiration date.
    public var expiresAt: Date {
        issuedAt.addingTimeInterval(expiresIn)
    }
    
    /// Creates a new token expiration tracker.
    ///
    /// - Parameters:
    ///   - issuedAt: The date the token was issued (defaults to now).
    ///   - expiresIn: The duration in seconds until expiration.
    public init(issuedAt: Date = Date(), expiresIn: TimeInterval) {
        self.issuedAt = issuedAt
        self.expiresIn = expiresIn
    }
    
    /// Whether the token has expired.
    ///
    /// - Parameter date: The reference date to check against (defaults to now).
    /// - Returns: `true` if the token has expired.
    public func isExpired(at date: Date = Date()) -> Bool {
        date >= expiresAt
    }
    
    /// Whether the token is expiring soon.
    ///
    /// This is useful for preemptive token refresh to avoid race conditions.
    ///
    /// - Parameters:
    ///   - threshold: How many seconds before expiration to consider "soon".
    ///   - date: The reference date to check against (defaults to now).
    /// - Returns: `true` if the token expires within the threshold.
    public func isExpiringSoon(threshold: TimeInterval = 300, at date: Date = Date()) -> Bool {
        let expirationWindow = expiresAt.addingTimeInterval(-threshold)
        return date >= expirationWindow
    }
    
    public static func == (lhs: TokenExpiration, rhs: TokenExpiration) -> Bool {
        // Compare with a small tolerance for floating point precision
        let dateTolerance: TimeInterval = 0.001
        return abs(lhs.issuedAt.timeIntervalSince1970 - rhs.issuedAt.timeIntervalSince1970) < dateTolerance &&
               abs(lhs.expiresIn - rhs.expiresIn) < dateTolerance
    }
}
