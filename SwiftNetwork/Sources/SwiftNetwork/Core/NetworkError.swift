//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

public enum NetworkError: Error, Sendable {
    case cancelled
    case invalidResponse
    case transportError(Error)
}
