//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public protocol TokenStore: Sendable {
    
    func currentToken() async -> String?
    
    func updateToken(_ newToken: String) async
}
