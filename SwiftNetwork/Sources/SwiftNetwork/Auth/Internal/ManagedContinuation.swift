//
//  ManagedContinuation.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Foundation

/// Thread-safe wrapper for managing checked continuations.
///
/// `ManagedContinuation` ensures safe resumption of async operations
/// by storing the continuation in an actor-isolated context.
actor ManagedContinuation<T: Sendable> {
    private var continuation: CheckedContinuation<T, Error>?
    
    /// Waits for the continuation to be resumed with a value or error.
    var value: T {
        get async throws {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        }
    }
    
    /// Resumes the continuation with a successful value.
    ///
    /// - Parameter value: The value to return from the suspended operation.
    func resume(returning value: T) {
        continuation?.resume(returning: value)
        continuation = nil
    }
    
    /// Resumes the continuation with an error.
    ///
    /// - Parameter error: The error to throw from the suspended operation.
    func resume(throwing error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
