//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public extension NetworkClient {

    /// Performs a GET request and decodes the response into the expected type.
    ///
    /// - Parameters:
    ///   - path: The request path or URL string.
    ///   - headers: Additional headers to include in the request.
    ///   - cachePolicy: Defines how caching should be applied.
    /// - Returns: A decoded response of type `T`.
    func get<T: Decodable>(
        _ path: String,
        headers: HTTPHeaders = [:],
        cachePolicy: CachePolicy = .useCache
    ) async throws -> T {
        try await request(
            method: .get,
            path: path,
            headers: headers,
            body: nil,
            cachePolicy: cachePolicy
        )
    }

    /// Performs a POST request with an encodable body and decodes the response.
    ///
    /// - Parameters:
    ///   - path: The request path or URL string.
    ///   - body: The encodable request body.
    ///   - headers: Additional headers to include in the request.
    /// - Returns: A decoded response of type `T`.
    func post<T: Decodable, Body: Encodable & Sendable>(
        _ path: String,
        body: Body,
        headers: HTTPHeaders = [:]
    ) async throws -> T {
        return try await request(
            method: .post,
            path: path,
            headers: headers,
            body: .json(body),
            cachePolicy: .ignoreCache
        )
    }

    /// Executes a request and decodes the response into the expected type.
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use.
    ///   - path: The request path or URL string.
    ///   - headers: Headers to include in the request.
    ///   - body: Optional request body.
    ///   - cachePolicy: Defines how caching should be applied.
    /// - Returns: A decoded response of type `T`.
    private func request<T: Decodable>(
        method: HTTPMethod,
        path: String,
        headers: HTTPHeaders,
        body: RequestBody?,
        cachePolicy: CachePolicy
    ) async throws -> T {
        let url = URL(string: path)!
        
        let request = Request(
            method: method,
            url: url,
            headers: headers,
            body: body,
            cachePolicy: cachePolicy
        )

        return try await newCall(request).execute()
    }
}
