//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

final class URLSessionTransport: Transport {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

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

    private func makeURLRequest(from request: Request) throws -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = request.timeout ?? urlRequest.timeoutInterval

        for (key, value) in request.headers.all {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        return urlRequest
    }
}
