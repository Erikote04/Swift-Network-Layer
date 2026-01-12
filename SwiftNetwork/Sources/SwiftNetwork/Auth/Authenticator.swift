//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// Defines an object capable of authenticating requests.
///
/// `Authenticator` is responsible for handling authentication challenges
/// (such as HTTP 401 responses) by producing a new authenticated request
/// or signaling that authentication cannot be performed.
public protocol Authenticator: Sendable {

    /// Attempts to authenticate a failed request.
    ///
    /// This method is called when a request receives an authentication
    /// challenge (typically a `401 Unauthorized` response).
    ///
    /// - Parameters:
    ///   - request: The original request that failed authentication.
    ///   - response: The response indicating an authentication failure.
    /// - Returns: A new authenticated request, or `nil` if authentication cannot be performed.
    /// - Throws: An error if authentication fails unexpectedly.
    func authenticate(request: Request, response: Response) async throws -> Request?
}
