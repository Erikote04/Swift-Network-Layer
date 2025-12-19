//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public struct LoggingInterceptor: Interceptor {

    public enum Level: Sendable {
        case none
        case basic
        case headers
        case body
    }

    private let level: Level

    public init(level: Level = .basic) {
        self.level = level
    }

    public func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        guard level != .none else {
            return try await chain.proceed(chain.request)
        }

        let request = chain.request
        let start = Date()

        logRequest(request)

        let response: Response
        
        do {
            response = try await chain.proceed(request)
        } catch {
            logError(error, request: request)
            throw error
        }

        let duration = Date().timeIntervalSince(start)
        logResponse(response, duration: duration)

        return response
    }

    private func logRequest(_ request: Request) {
        print("➡️ \(request.method) \(request.url.absoluteString)")

        guard level != .basic else { return }

        if !request.headers.all.isEmpty {
            print("Headers:")
            request.headers.all.forEach { print("  \($0): \($1)") }
        }

        guard level == .body else { return }

        if let body = request.body,
           let bodyString = String(data: body, encoding: .utf8) {
            print("Body:")
            print(bodyString)
        }
    }

    private func logResponse(_ response: Response, duration: TimeInterval) {
        print("⬅️ \(response.statusCode) (\(String(format: "%.2f", duration))s)")

        guard level != .basic else { return }

        if !response.headers.all.isEmpty {
            print("Headers:")
            response.headers.all.forEach { print("  \($0): \($1)") }
        }

        guard level == .body else { return }

        if let body = response.body,
           let bodyString = String(data: body, encoding: .utf8) {
            print("Body:")
            print(bodyString)
        }
    }

    private func logError(_ error: Error, request: Request) {
        print("❌ Error \(request.method) \(request.url.absoluteString)")
        print(error)
    }
}
