//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Foundation
@testable import SwiftNetwork

actor RecordingInterceptor: Interceptor {

    let id: String
    private let recorder: Recorder

    init(id: String, recorder: Recorder) {
        self.id = id
        self.recorder = recorder
    }

    func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        await recorder.record(id)
        return try await chain.proceed(chain.request)
    }
}
