//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

public protocol Call: Sendable {

    var request: Request { get }

    func execute() async throws -> Response

    func cancel()

    var isCancelled: Bool { get }
}
