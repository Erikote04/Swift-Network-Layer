//
//  ConditionalInterceptor.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork on 20/1/26.
//

import Foundation

/// An interceptor that conditionally executes based on request properties.
///
/// `ConditionalInterceptor` wraps another interceptor and only executes it
/// when specific conditions are met, such as matching host, method, or headers.
public struct ConditionalInterceptor: Interceptor {
    
    /// A condition that determines whether the interceptor should execute.
    public struct Condition: Sendable {
        private let predicate: @Sendable (Request) -> Bool
        
        fileprivate init(predicate: @escaping @Sendable (Request) -> Bool) {
            self.predicate = predicate
        }
        
        /// Evaluates the condition for a given request.
        ///
        /// - Parameter request: The request to evaluate.
        /// - Returns: `true` if the condition is met.
        public func evaluate(_ request: Request) -> Bool {
            predicate(request)
        }
        
        /// Combines two conditions with logical AND.
        ///
        /// - Parameter other: The condition to combine with.
        /// - Returns: A new condition that passes only if both conditions pass.
        public func and(_ other: Condition) -> Condition {
            Condition { request in
                self.evaluate(request) && other.evaluate(request)
            }
        }
        
        /// Combines two conditions with logical OR.
        ///
        /// - Parameter other: The condition to combine with.
        /// - Returns: A new condition that passes if either condition passes.
        public func or(_ other: Condition) -> Condition {
            Condition { request in
                self.evaluate(request) || other.evaluate(request)
            }
        }
        
        /// Negates the condition.
        ///
        /// - Returns: A new condition that passes when this condition fails.
        public func not() -> Condition {
            Condition { request in
                !self.evaluate(request)
            }
        }
    }
    
    private let interceptor: Interceptor
    private let condition: Condition
    
    /// Creates a conditional interceptor.
    ///
    /// - Parameters:
    ///   - interceptor: The interceptor to conditionally execute.
    ///   - condition: The condition that must be met for execution.
    public init(interceptor: Interceptor, condition: Condition) {
        self.interceptor = interceptor
        self.condition = condition
    }
    
    public func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        if condition.evaluate(chain.request) {
            return try await interceptor.intercept(chain)
        } else {
            return try await chain.proceed(chain.request)
        }
    }
}

// MARK: - Condition Builders

public extension ConditionalInterceptor.Condition {
    
    /// Creates a condition that matches requests for a specific host.
    ///
    /// - Parameter host: The host to match (e.g., "api.example.com").
    /// - Returns: A condition that passes when the request host matches.
    static func forHost(_ host: String) -> ConditionalInterceptor.Condition {
        ConditionalInterceptor.Condition { request in
            request.url.host == host
        }
    }
    
    /// Creates a condition that matches requests with a specific HTTP method.
    ///
    /// - Parameter method: The HTTP method to match.
    /// - Returns: A condition that passes when the request method matches.
    static func forMethod(_ method: HTTPMethod) -> ConditionalInterceptor.Condition {
        ConditionalInterceptor.Condition { request in
            request.method == method
        }
    }
    
    /// Creates a condition that matches requests with a path prefix.
    ///
    /// - Parameter pathPrefix: The path prefix to match (e.g., "/api/v1").
    /// - Returns: A condition that passes when the request path starts with the prefix.
    static func forPath(_ pathPrefix: String) -> ConditionalInterceptor.Condition {
        ConditionalInterceptor.Condition { request in
            request.url.path.hasPrefix(pathPrefix)
        }
    }
    
    /// Creates a condition that matches requests with a specific header value.
    ///
    /// - Parameters:
    ///   - name: The header name to check.
    ///   - value: The expected header value.
    /// - Returns: A condition that passes when the header matches.
    static func forHeader(_ name: String, value: String) -> ConditionalInterceptor.Condition {
        ConditionalInterceptor.Condition { request in
            request.headers[name] == value
        }
    }
    
    /// Creates a custom condition using a predicate.
    ///
    /// - Parameter predicate: A closure that evaluates the request.
    /// - Returns: A condition that passes when the predicate returns `true`.
    static func custom(_ predicate: @escaping @Sendable (Request) -> Bool) -> ConditionalInterceptor.Condition {
        ConditionalInterceptor.Condition(predicate: predicate)
    }
}
