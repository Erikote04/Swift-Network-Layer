//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public extension Call {
    
    func execute<T: Decodable>(decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        let response = try await execute()
        try ResponseValidator.validate(response)

        guard let data = response.body else {
            throw NetworkError.noData
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
