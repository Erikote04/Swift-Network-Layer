//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

/// Validates HTTP responses.
///
/// `ResponseValidator` centralizes response validation logic and
/// converts non-successful HTTP responses into domain-specific errors.
struct ResponseValidator {

    /// Validates a response and throws an error if it is not successful.
    ///
    /// - Parameter response: The response to validate.
    /// - Throws: A `NetworkError.httpError` if the response status code indicates a failure.
    static func validate(_ response: Response) throws {
        guard response.isSuccessful else {
            throw NetworkError.httpError(
                statusCode: response.statusCode,
                body: response.body
            )
        }
    }
}
