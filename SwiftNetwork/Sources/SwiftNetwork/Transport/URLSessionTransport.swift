//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// A `Transport` implementation backed by `URLSession`.
///
/// `URLSessionTransport` adapts SwiftNetwork requests to `URLSession`,
/// handling request conversion, execution, and response mapping.
final class URLSessionTransport: Transport {

    private let session: URLSession

    /// Creates a new URLSession-based transport.
    ///
    /// - Parameter session: The URLSession instance used to perform requests.
    ///   Defaults to `URLSession.shared`.
    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Executes a request using `URLSession`.
    ///
    /// - Parameter request: The request to execute.
    /// - Returns: A `Response` containing the server response.
    /// - Throws: A `NetworkError` if execution fails, is cancelled,
    ///   or the response is invalid.
    func execute(_ request: Request) async throws -> Response {
        let urlRequest = try makeURLRequest(from: request)

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            return Response(
                request: request,
                statusCode: httpResponse.statusCode,
                headers: HTTPHeaders(httpResponse.allHeaderFields as? [String: String] ?? [:]),
                body: data
            )
        } catch is CancellationError {
            throw NetworkError.cancelled
        } catch {
            throw NetworkError.transportError(error)
        }
    }

    /// Converts a `Request` into a `URLRequest`.
    ///
    /// - Parameter request: The SwiftNetwork request to convert.
    /// - Returns: A configured `URLRequest`.
    /// - Throws: An error if request construction or body encoding fails.
    private func makeURLRequest(from request: Request) throws -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = request.timeout ?? urlRequest.timeoutInterval
        
        // Encode the body if present
        if let body = request.body {
            urlRequest.httpBody = try body.encoded()
            
            // Set Content-Type header if not already provided
            if request.headers["Content-Type"] == nil {
                urlRequest.setValue(body.contentType, forHTTPHeaderField: "Content-Type")
            }
        }

        // Apply all headers from the request
        for (key, value) in request.headers.all {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        return urlRequest
    }
}
