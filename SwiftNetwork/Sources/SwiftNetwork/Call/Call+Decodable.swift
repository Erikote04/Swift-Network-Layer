//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

public extension Call {

    /// Executes the call and decodes the response body into a decodable type.
    ///
    /// The response is validated before decoding. If the response body
    /// is missing or decoding fails, an appropriate `NetworkError` is thrown.
    ///
    /// - Parameter decoder: The JSON decoder used to decode the response body.
    /// - Returns: A decoded value of type `T`.
    /// - Throws: A `NetworkError` if validation, decoding, or execution fails.
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
