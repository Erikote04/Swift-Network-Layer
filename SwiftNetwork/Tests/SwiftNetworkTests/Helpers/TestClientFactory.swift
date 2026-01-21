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
        prioritizedInterceptors: [PrioritizedInterceptor] = []
    ) -> NetworkClient {
        let sortedPrioritized = prioritizedInterceptors
            .sorted()
            .map { $0.interceptor }
        
        let allInterceptors = sortedPrioritized + interceptors
        
        return NetworkClient(
            transport: transport,
            interceptors: allInterceptors
        )
    }
}
