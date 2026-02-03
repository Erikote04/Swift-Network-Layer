//
//  DeduplicatedCall.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 28/1/26.
//

import Foundation

/// A call wrapper that deduplicates identical in-flight requests.
///
/// `DeduplicatedCall` wraps another call implementation and ensures that
/// multiple concurrent identical requests share a single execution.
///
/// Type used internally by `NetworkClient` when deduplication
/// is enabled in the configuration.
struct DeduplicatedCall: Call {
    
    private let baseCall: Call
    private let deduplicator: RequestDeduplicator
    
    var request: Request { baseCall.request }
    
    /// Creates a new deduplicated call wrapper.
    ///
    /// - Parameters:
    ///   - baseCall: The underlying call to deduplicate.
    ///   - deduplicator: The deduplicator to use for sharing requests.
    init(
        baseCall: Call,
        deduplicator: RequestDeduplicator
    ) {
        self.baseCall = baseCall
        self.deduplicator = deduplicator
    }
    
    func execute() async throws -> Response {
        try await deduplicator.deduplicate(request: request) { [baseCall] in
            try await baseCall.execute()
        }
    }
    
    func cancel() async {
        await baseCall.cancel()
    }

    func isCancelled() async -> Bool {
        await baseCall.isCancelled()
    }
}
