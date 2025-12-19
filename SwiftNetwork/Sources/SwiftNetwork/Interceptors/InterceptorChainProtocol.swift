//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public protocol InterceptorChainProtocol: Sendable {

    var request: Request { get }

    func proceed(_ request: Request) async throws -> Response
}
