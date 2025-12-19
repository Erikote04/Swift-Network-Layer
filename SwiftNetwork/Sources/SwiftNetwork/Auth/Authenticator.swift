//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public protocol Authenticator: Sendable {

    /// Called when a request receives an authentication challenge (e.g. 401).
    /// Return a new authenticated request, or nil to give up.
    func authenticate(request: Request, response: Response) async throws -> Request?
}
