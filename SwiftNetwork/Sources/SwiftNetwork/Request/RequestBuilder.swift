//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

public struct RequestBuilder {
    private var method: HTTPMethod
    private var url: URL
    private var headers: HTTPHeaders = [:]
    private var body: Data?
    private var timeout: TimeInterval?

    public init(method: HTTPMethod, url: URL) {
        self.method = method
        self.url = url
    }

    public mutating func header(_ name: String, _ value: String) -> Self {
        headers[name] = value
        return self
    }

    public mutating func headers(_ headers: HTTPHeaders) -> Self {
        self.headers = self.headers.merging(headers)
        return self
    }

    public mutating func body(_ data: Data?) -> Self {
        self.body = data
        return self
    }

    public mutating func timeout(_ interval: TimeInterval) -> Self {
        self.timeout = interval
        return self
    }

    public func build() -> Request {
        Request(
            method: method,
            url: url,
            headers: headers,
            body: body,
            timeout: timeout
        )
    }
}
