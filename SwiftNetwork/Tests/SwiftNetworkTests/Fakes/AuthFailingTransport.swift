//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Foundation
@testable import SwiftNetwork

actor AuthFailingTransport: Transport {

    func execute(_ request: Request) async throws -> Response {
        let auth = request.headers["Authorization"]

        if auth == "Bearer expired" {
            return Response(
                request: request,
                statusCode: 401,
                headers: [:],
                body: nil
            )
        }

        return Response(
            request: request,
            statusCode: 200,
            headers: [:],
            body: Data("ok".utf8)
        )
    }
}
