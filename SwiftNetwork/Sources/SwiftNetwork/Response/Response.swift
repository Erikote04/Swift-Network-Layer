//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

public struct Response: Sendable {
    public let request: Request
    public let statusCode: Int
    public let headers: HTTPHeaders
    public let body: Data?

    public init(
        request: Request,
        statusCode: Int,
        headers: HTTPHeaders = [:],
        body: Data? = nil
    ) {
        self.request = request
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

public extension Response {
    var isSuccessful: Bool {
        (200..<300).contains(statusCode)
    }
}
