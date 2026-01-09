//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Foundation
@testable import SwiftNetwork

actor FakeTokenStore: TokenStore {

    private(set) var token: String?
    private(set) var updates: Int = 0

    init(initialToken: String?) {
        self.token = initialToken
    }

    func currentToken() async -> String? {
        token
    }

    func updateToken(_ newToken: String) async {
        token = newToken
        updates += 1
    }
}
