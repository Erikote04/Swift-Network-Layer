//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// An interceptor that logs requests and responses.
///
/// `LoggingInterceptor` supports multiple verbosity levels,
/// ranging from basic request/response information to full headers
/// and body logging.
public struct LoggingInterceptor: Interceptor {

    /// Defines the logging verbosity level.
    public enum Level: Sendable {
        case none
        case basic
        case headers
        case body
    }

    private let level: Level

    /// Creates a new logging interceptor.
    ///
    /// - Parameter level: The desired logging level.
    public init(level: Level = .basic) {
        self.level = level
    }

    /// Intercepts a request to log request and response details.
    ///
    /// - Parameter chain: The interceptor chain.
    /// - Returns: The resulting `Response`.
    /// - Throws: Any error produced during request execution.
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

        if let body = request.body {
            print("Body (\(body.contentType)):")
            
            // Try to encode and display the body
            do {
                let bodyData = try body.encoded()
                if let bodyString = String(data: bodyData, encoding: .utf8) {
                    print(bodyString)
                } else {
                    print("<binary data, \(bodyData.count) bytes>")
                }
            } catch {
                print("<failed to encode body: \(error)>")
            }
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
