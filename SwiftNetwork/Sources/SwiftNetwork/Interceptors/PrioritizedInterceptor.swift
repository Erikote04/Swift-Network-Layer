//
//  PrioritizedInterceptor.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork on 20/1/26.
//

import Foundation

/// A wrapper that associates an interceptor with a priority value.
///
/// Higher priority interceptors execute earlier in the chain.
/// Interceptors with the same priority maintain their original order.
public struct PrioritizedInterceptor: Sendable {
    
    /// The underlying interceptor to execute.
    public let interceptor: Interceptor
    
    /// The execution priority. Higher values execute first.
    public let priority: Int
    
    /// Creates a new prioritized interceptor.
    ///
    /// - Parameters:
    ///   - interceptor: The interceptor to wrap.
    ///   - priority: The execution priority (default: 0).
    public init(interceptor: Interceptor, priority: Int = 0) {
        self.interceptor = interceptor
        self.priority = priority
    }
}

extension PrioritizedInterceptor: Comparable {
    public static func == (lhs: PrioritizedInterceptor, rhs: PrioritizedInterceptor) -> Bool {
        lhs.priority == rhs.priority
    }
    
    public static func < (lhs: PrioritizedInterceptor, rhs: PrioritizedInterceptor) -> Bool {
        lhs.priority > rhs.priority // Higher priority comes first
    }
}
