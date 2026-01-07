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
        interceptors: [Interceptor] = []
    ) -> NetworkClient {
        NetworkClient(
            transport: transport,
            interceptors: interceptors
        )
    }
}
