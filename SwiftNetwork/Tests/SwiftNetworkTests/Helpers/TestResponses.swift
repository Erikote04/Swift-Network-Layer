//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Foundation
@testable import SwiftNetwork

enum TestResponses {

    static func success(
        request: Request,
        statusCode: Int = 200,
        body: Data? = nil
    ) -> Response {
        Response(
            request: request,
            statusCode: statusCode,
            headers: [:],
            body: body
        )
    }

    static func error(
        request: Request,
        statusCode: Int,
        body: Data? = nil
    ) -> Response {
        Response(
            request: request,
            statusCode: statusCode,
            headers: [:],
            body: body
        )
    }
}
