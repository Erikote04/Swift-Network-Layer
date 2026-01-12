//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// Represents a single executable network request.
///
/// A `Call` encapsulates a request that can be executed, cancelled,
/// and queried for its cancellation state.
public protocol Call: Sendable {

    /// The request associated with this call.
    var request: Request { get }

    /// Executes the call asynchronously.
    ///
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error encountered during execution.
    func execute() async throws -> Response

    /// Cancels the call.
    func cancel()

    /// Indicates whether the call has been cancelled.
    var isCancelled: Bool { get }
}
