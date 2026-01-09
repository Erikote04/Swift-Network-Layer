//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

enum CallState: Sendable {
    
    case idle
    case running
    case completed
    case cancelled
}
