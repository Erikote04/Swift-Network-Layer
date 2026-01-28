//
//  RequestPriority.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 28/1/26.
//

import Foundation

/// Represents the priority level of a network request.
///
/// Request priorities allow the system to schedule and execute requests
/// in an order that reflects their importance to the user experience.
///
/// Higher priority requests may be executed before lower priority ones
/// when system resources are constrained.
public enum RequestPriority: Int, Sendable, Comparable {
    
    /// Background priority for non-time-sensitive requests.
    ///
    /// Use this for prefetching, analytics, or other tasks that don't
    /// impact immediate user experience.
    case background = 0
    
    /// Low priority for requests that are not immediately visible.
    ///
    /// Suitable for loading content below the fold or preparing
    /// resources for future navigation.
    case low = 1
    
    /// Normal priority for standard user-initiated requests.
    ///
    /// This is the default priority for most requests.
    case normal = 2
    
    /// High priority for user-visible content.
    ///
    /// Use this for requests that directly impact what the user
    /// is currently viewing or interacting with.
    case high = 3
    
    /// Critical priority for essential, time-sensitive requests.
    ///
    /// Reserved for requests that must complete immediately,
    /// such as authentication or payment transactions.
    case critical = 4
    
    public static func < (lhs: RequestPriority, rhs: RequestPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    /// Maps the request priority to a URLSessionTask priority.
    ///
    /// - Returns: A task priority value between 0.0 and 1.0.
    internal var taskPriority: Float {
        switch self {
        case .background: return 0.0
        case .low: return 0.25
        case .normal: return 0.5
        case .high: return 0.75
        case .critical: return 1.0
        }
    }
    
    /// Maps the request priority to a Task priority.
    ///
    /// - Returns: A Swift concurrency task priority.
    internal var swiftTaskPriority: TaskPriority {
        switch self {
        case .background: return .background
        case .low: return .low
        case .normal: return .medium
        case .high: return .high
        case .critical: return .userInitiated
        }
    }
}
