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
open class BaseCall: Call, @unchecked Sendable {

    /// The request associated with this call.
    public let request: Request

    private let stateLock = NSLock()
    private var state: CallState = .idle

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
        stateLock.lock()
        state = .cancelled
        stateLock.unlock()
    }

    /// Indicates whether the call has been cancelled.
    public var isCancelled: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return state == .cancelled
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
        stateLock.lock()
        defer { stateLock.unlock() }

        guard state == .idle else {
            fatalError("Call can only be executed once")
        }

        state = .running
    }

    /// Marks the call as completed if it was not cancelled.
    private func finishExecution() {
        stateLock.lock()
        
        if state != .cancelled {
            state = .completed
        }
        
        stateLock.unlock()
    }
}
