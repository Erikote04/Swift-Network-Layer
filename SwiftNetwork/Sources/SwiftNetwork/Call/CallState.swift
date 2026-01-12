//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// Represents the lifecycle state of a `Call`.
enum CallState: Sendable {

    /// The call has been created but not yet executed.
    case idle

    /// The call is currently executing.
    case running

    /// The call has completed successfully.
    case completed

    /// The call has been cancelled.
    case cancelled
}
