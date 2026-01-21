//
//  FakeTransportFactory.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork on 20/1/26.
//

import Foundation
@testable import SwiftNetwork

enum FakeTransportFactory {
    
    static func success(
        statusCode: Int = 200,
        body: Data = Data()
    ) -> FakeTransport {
        FakeTransport { request in
            Response(
                request: request,
                statusCode: statusCode,
                headers: [:],
                body: body
            )
        }
    }
}
