//
//  FakeCountingTransport.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 8/1/26.
//

import Foundation
@testable import SwiftNetwork

actor FakeCountingTransport: Transport {
    
    private(set) var calls: Int = 0
    
    private let counter: CallCounter?
    private let response: Response?
    
    init(counter: CallCounter) {
        self.counter = counter
        self.response = nil
    }
    
    init(response: Response) {
        self.counter = nil
        self.response = response
    }
    
    func execute(_ request: Request) async throws -> Response {
        calls += 1
        
        if let counter = counter {
            _ = await counter.increment()
        }
        
        if let response = response {
            return response
        }
        
        return Response(
            request: request,
            statusCode: 200,
            headers: [:],
            body: Data()
        )
    }
}
