//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Foundation
@testable import SwiftNetwork

enum TestClientFactory {

    static func make(
        transport: Transport,
        interceptors: [Interceptor] = [],
        prioritizedInterceptors: [PrioritizedInterceptor] = [],
        requestInterceptors: [RequestInterceptor] = [],
        responseInterceptors: [ResponseInterceptor] = []
    ) -> NetworkClient {
        // Sort prioritized interceptors and extract them
        let sortedPrioritized = prioritizedInterceptors
            .sorted()
            .map { $0.interceptor }
        
        // Adapt request-only interceptors
        let requestAdapted = requestInterceptors
            .map { RequestResponseInterceptorAdapter(requestInterceptor: $0) }
        
        // Adapt response-only interceptors
        let responseAdapted = responseInterceptors
            .map { RequestResponseInterceptorAdapter(responseInterceptor: $0) }
        
        // Combine: prioritized → request → regular → response
        let allInterceptors = sortedPrioritized + requestAdapted + interceptors + responseAdapted
        
        return NetworkClient(
            transport: transport,
            interceptors: allInterceptors
        )
    }
}
