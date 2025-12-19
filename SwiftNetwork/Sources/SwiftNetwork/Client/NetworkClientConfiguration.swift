//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

public struct NetworkClientConfiguration: Sendable {
    
    public let baseURL: URL?
    public let defaultHeaders: HTTPHeaders
    public let timeout: TimeInterval
    public let interceptors: [Interceptor]

    public init(
        baseURL: URL? = nil,
        defaultHeaders: HTTPHeaders = [:],
        timeout: TimeInterval = 60,
        interceptors: [Interceptor] = []
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.timeout = timeout
        self.interceptors = interceptors
    }
}
