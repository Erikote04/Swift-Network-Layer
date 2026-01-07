//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Foundation
@testable import SwiftNetwork

actor FakeAuthenticator: Authenticator {
    
    private(set) var authenticateCalls: Int = 0
    private let newToken: String
    
    init(newToken: String) {
        self.newToken = newToken
    }
    
    func authenticate(
        request: Request,
        response: Response
    ) async throws -> Request? {
        authenticateCalls += 1
        
        var headers = request.headers
        headers["Authorization"] = "Bearer \(newToken)"
        
        return Request(
            method: request.method,
            url: request.url,
            headers: headers,
            body: request.body,
            timeout: request.timeout,
            cachePolicy: request.cachePolicy
        )
    }
}
