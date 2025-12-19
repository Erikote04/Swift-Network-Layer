//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

public struct Request: Sendable {
    
    public let method: HTTPMethod
    public let url: URL
    public let headers: HTTPHeaders
    public let body: Data?
    public let timeout: TimeInterval?
    public let cachePolicy: CachePolicy

    public init(
        method: HTTPMethod,
        url: URL,
        headers: HTTPHeaders = [:],
        body: Data? = nil,
        timeout: TimeInterval? = nil,
        cachePolicy: CachePolicy = .useCache
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.timeout = timeout
        self.cachePolicy = cachePolicy
    }
}
