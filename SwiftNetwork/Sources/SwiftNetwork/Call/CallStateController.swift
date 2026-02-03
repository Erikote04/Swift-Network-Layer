//
//  CallStateController.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation

/// Actor-isolated state controller for call lifecycle.
///
/// Ensures execution and cancellation state is safely managed across
/// concurrency domains without locks or unchecked Sendable conformance.
actor CallStateController {

    private var state: CallState = .idle

    func beginExecution() throws {
        guard state == .idle else {
            fatalError("Call can only be executed once")
        }
        state = .running
    }

    func finishExecution() {
        if state != .cancelled {
            state = .completed
        }
    }

    func cancel() {
        state = .cancelled
    }

    func isCancelled() -> Bool {
        state == .cancelled
    }
}
