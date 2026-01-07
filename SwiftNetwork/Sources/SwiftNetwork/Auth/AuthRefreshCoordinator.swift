//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Foundation

actor AuthRefreshCoordinator {

    private var refreshTask: Task<String?, Error>? = nil

    func refreshIfNeeded(
        tokenStore: TokenStore,
        authenticate: @escaping @Sendable () async throws -> String?
    ) async throws -> String? {

        if let task = refreshTask {
            return try await task.value
        }

        let task = Task<String?, Error> {
            defer { refreshTask = nil }

            guard let token = try await authenticate() else {
                return nil
            }

            await tokenStore.updateToken(token)
            return token
        }

        refreshTask = task
        return try await task.value
    }
}
