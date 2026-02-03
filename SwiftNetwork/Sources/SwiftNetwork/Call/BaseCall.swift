//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// A base implementation of a network call.
///
/// `BaseCall` provides shared execution, cancellation, and lifecycle
/// management logic for concrete `Call` implementations.
/// Subclasses are responsible for performing the actual execution.
///
/// - Safety: Internal state is protected by `ManagedCriticalState` to ensure
///   thread-safe access across concurrency domains. Subclasses must not
///   mutate shared state without appropriate synchronization.
open class BaseCall: Call, @unchecked Sendable {

    /// The request associated with this call.
    public let request: Request

    private let state = ManagedCriticalState<CallState>(.idle)

    /// Creates a new base call.
    ///
    /// - Parameter request: The request to be executed.
    public init(request: Request) {
        self.request = request
    }

    /// Executes the call asynchronously.
    ///
    /// This method ensures the call is only executed once, handles
    /// cancellation checks, and manages the call lifecycle.
    ///
    /// - Returns: The resulting `Response`.
    /// - Throws: A `NetworkError` if the call is cancelled or execution fails.
    public final func execute() async throws -> Response {
        try beginExecution()
        
        defer { finishExecution() }

        if isCancelled {
            throw NetworkError.cancelled
        }

        return try await performExecute()
    }

    /// Cancels the call.
    ///
    /// If the call is already running, it will be marked as cancelled
    /// and execution should stop as soon as possible.
    public func cancel() {
        state.withCriticalRegion { $0 = .cancelled }
    }

    /// Indicates whether the call has been cancelled.
    public var isCancelled: Bool {
        state.withCriticalRegion { $0 == .cancelled }
    }

    // MARK: - Overridable

    /// Performs the actual execution of the call.
    ///
    /// Subclasses must override this method to provide the concrete
    /// execution behavior.
    ///
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error encountered during execution.
    open func performExecute() async throws -> Response {
        fatalError("Subclasses must override performExecute()")
    }

    // MARK: - State

    /// Marks the call as running.
    ///
    /// - Throws: A fatal error if the call is executed more than once.
    private func beginExecution() throws {
        state.withCriticalRegion { currentState in
            guard currentState == .idle else {
                fatalError("Call can only be executed once")
            }

            currentState = .running
        }
    }

    /// Marks the call as completed if it was not cancelled.
    private func finishExecution() {
        state.withCriticalRegion { currentState in
            if currentState != .cancelled {
                currentState = .completed
            }
        }
    }
}
