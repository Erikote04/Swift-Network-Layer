//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

protocol Transport: Sendable {
    
    func execute(_ request: Request) async throws -> Response
}
