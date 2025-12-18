//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

public protocol NetworkClientProtocol: Sendable {
    
    func newCall(_ request: Request) -> Call
}
