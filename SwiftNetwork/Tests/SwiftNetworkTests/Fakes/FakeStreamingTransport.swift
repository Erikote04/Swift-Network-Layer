//
//  FakeStreamingTransport.swift
//  SwiftNetworkTests
//
//  Created by SwiftNetwork Contributors on 2/3/26.
//

import Foundation
@testable import SwiftNetwork

actor FakeStreamingTransport: ProgressReportingTransport, StreamingTransport {

    private let chunkSize: Int
    private let defaultStatusCode: Int
    private let headers: HTTPHeaders

    init(
        chunkSize: Int = 8_192,
        statusCode: Int = 200,
        headers: HTTPHeaders = [:]
    ) {
        self.chunkSize = chunkSize
        self.defaultStatusCode = statusCode
        self.headers = headers
    }

    func execute(_ request: Request) async throws -> Response {
        let statusCode = statusCode(for: request)
        let body = responseBody(for: request)
        return Response(
            request: request,
            statusCode: statusCode,
            headers: headers,
            body: body.isEmpty ? nil : body
        )
    }

    func execute(
        _ request: Request,
        progress: (@Sendable (SwiftNetwork.Progress) -> Void)?
    ) async throws -> Response {
        if let progressHandler = progress {
            let totalBytes = Int64((try? request.body?.encoded().count) ?? 0)
            if totalBytes > 0 {
                let step = max(Int64(1), totalBytes / 3)
                var sent: Int64 = 0
                while sent < totalBytes {
                    sent = min(totalBytes, sent + step)
                    progressHandler(SwiftNetwork.Progress(bytesTransferred: sent, totalBytes: totalBytes))
                }
            } else {
                progressHandler(SwiftNetwork.Progress(bytesTransferred: 0, totalBytes: 0))
            }
        }

        return try await execute(request)
    }

    func stream(_ request: Request) async throws -> StreamingResponse {
        let statusCode = statusCode(for: request)
        let body = responseBody(for: request)

        let stream = AsyncThrowingStream<Data, Error> { continuation in
            Task {
                guard !body.isEmpty else {
                    continuation.finish()
                    return
                }

                var offset = 0
                while offset < body.count {
                    let end = min(offset + chunkSize, body.count)
                    continuation.yield(body.subdata(in: offset..<end))
                    offset = end
                }
                continuation.finish()
            }
        }

        return StreamingResponse(
            request: request,
            statusCode: statusCode,
            headers: headers,
            stream: stream
        )
    }

    private func statusCode(for request: Request) -> Int {
        if let status = parseStatus(from: request.url) {
            return status
        }
        return defaultStatusCode
    }

    private func responseBody(for request: Request) -> Data {
        if let bytes = parseBytes(from: request.url) {
            return Data(repeating: 0xA5, count: bytes)
        }
        return Data("OK".utf8)
    }

    private func parseBytes(from url: URL) -> Int? {
        let components = url.path.split(separator: "/")
        guard components.count >= 2, components[components.count - 2] == "bytes" else {
            return nil
        }
        return Int(components.last ?? "")
    }

    private func parseStatus(from url: URL) -> Int? {
        let components = url.path.split(separator: "/")
        guard components.count >= 2, components[components.count - 2] == "status" else {
            return nil
        }
        return Int(components.last ?? "")
    }
}
