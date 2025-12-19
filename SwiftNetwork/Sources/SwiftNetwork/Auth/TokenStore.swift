//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public actor TokenStore {
    private var token: String?
    private var refreshTask: Task<String, Error>?

    public init(initialToken: String? = nil) {
        self.token = initialToken
    }

    public func currentToken() -> String? {
        token
    }

    public func update(token: String) {
        self.token = token
    }

    public func refreshIfNeeded(refreshAction: @escaping @Sendable () async throws -> String) async throws -> String {
        if let task = refreshTask {
            return try await task.value
        }

        let task = Task {
            defer { refreshTask = nil }
            let newToken = try await refreshAction()
            self.token = newToken
            return newToken
        }

        refreshTask = task
        return try await task.value
    }
}
