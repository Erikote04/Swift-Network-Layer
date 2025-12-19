//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 19/12/25.
//

import Foundation

struct ResponseValidator {
    
    static func validate(_ response: Response) throws {
        guard response.isSuccessful else {
            throw NetworkError.httpError(
                statusCode: response.statusCode,
                body: response.body
            )
        }
    }
}
