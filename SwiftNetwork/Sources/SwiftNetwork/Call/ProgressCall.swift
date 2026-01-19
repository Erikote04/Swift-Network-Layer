//
//  ProgressCall.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 19/1/26.
//

import Foundation

/// Represents progress information for an ongoing network operation.
///
/// `Progress` encapsulates the current state of an upload or download operation,
/// providing both raw byte counts and a normalized completion fraction.
public struct Progress: Sendable {
    
    /// The number of bytes transferred so far.
    public let bytesTransferred: Int64
    
    /// The total number of bytes expected to be transferred.
    ///
    /// This value may be `-1` if the total size is unknown (e.g., chunked transfer encoding).
    public let totalBytes: Int64
    
    /// The fraction of work completed, from 0.0 to 1.0.
    ///
    /// Returns `0.0` if the total bytes is unknown or zero.
    public var fractionCompleted: Double {
        guard totalBytes > 0 else { return 0.0 }
        return Double(bytesTransferred) / Double(totalBytes)
    }
    
    /// Creates a new progress instance.
    ///
    /// - Parameters:
    ///   - bytesTransferred: The number of bytes transferred.
    ///   - totalBytes: The total expected bytes, or `-1` if unknown.
    public init(bytesTransferred: Int64, totalBytes: Int64) {
        self.bytesTransferred = bytesTransferred
        self.totalBytes = totalBytes
    }
}

/// A protocol for calls that support progress reporting.
///
/// `ProgressCall` extends the basic `Call` protocol with the ability to
/// report upload and download progress through a callback handler.
///
/// Progress callbacks are invoked on a background queue and should not
/// perform heavy UI work directly. Use `@MainActor` or `DispatchQueue.main`
/// if UI updates are needed.
///
/// ## Example Usage
///
/// ```swift
/// let call = client.newCall(uploadRequest)
///
/// if let progressCall = call as? ProgressCall {
///     let response = try await progressCall.execute { progress in
///         print("Uploaded: \(progress.fractionCompleted * 100)%")
///     }
/// }
/// ```
public protocol ProgressCall: Call {
    
    /// Executes the call with progress reporting.
    ///
    /// The progress handler is called periodically during upload and download
    /// operations. The frequency of updates depends on the underlying transport
    /// and network conditions.
    ///
    /// - Parameter progress: A closure called with progress updates.
    ///   This closure is called on a background queue and must be `@Sendable`.
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error encountered during execution.
    ///
    /// - Note: The progress handler may not be called for very small requests
    ///   or if the server doesn't provide content-length information.
    func execute(
        progress: @escaping @Sendable (Progress) -> Void
    ) async throws -> Response
}

// MARK: - Default Implementation

extension ProgressCall {
    
    /// Executes the call without progress reporting.
    ///
    /// This default implementation satisfies the `Call` protocol requirement
    /// by executing with a no-op progress handler.
    ///
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error encountered during execution.
    public func execute() async throws -> Response {
        try await execute(progress: { _ in })
    }
}
