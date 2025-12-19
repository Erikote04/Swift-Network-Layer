//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public extension NetworkClient {

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

    func post<T: Decodable, Body: Encodable>(
        _ path: String,
        body: Body,
        headers: HTTPHeaders = [:]
    ) async throws -> T {
        let data = try JSONEncoder().encode(body)
        
        return try await request(
            method: .post,
            path: path,
            headers: headers,
            body: data,
            cachePolicy: .reloadIgnoringCache
        )
    }

    private func request<T: Decodable>(
        method: HTTPMethod,
        path: String,
        headers: HTTPHeaders,
        body: Data?,
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
