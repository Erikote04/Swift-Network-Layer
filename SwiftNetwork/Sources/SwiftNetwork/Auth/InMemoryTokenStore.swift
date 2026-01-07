//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Foundation

public actor InMemoryTokenStore: TokenStore {

    private var token: String?

    public init(initialToken: String? = nil) {
        self.token = initialToken
    }

    public func currentToken() async -> String? {
        token
    }

    public func updateToken(_ newToken: String) async {
        token = newToken
    }
}
