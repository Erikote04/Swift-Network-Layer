//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// Defines the minimal interface required to create executable network calls.
///
/// This protocol allows `NetworkClient` to be abstracted or mocked
/// without exposing implementation details.
public protocol NetworkClientProtocol: Sendable {

    /// Creates a new executable call for the given request.
    ///
    /// - Parameter request: The request to execute.
    /// - Returns: A `Call` representing the executable request.
    func newCall(_ request: Request) -> Call
}
