//
//  RequestResponseInterceptorsDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class RequestResponseInterceptorsDemoViewModel {
    enum State {
        case idle
        case loading
        case success(body: String)
        case failed(String)
    }

    struct SampleError: LocalizedError {
        let statusCode: Int

        var errorDescription: String? {
            "Response interceptor blocked status \(statusCode)."
        }
    }

    var state: State = .idle
    var requestId: String = ""
    var responseHeaders: [String: String] = [:]
    var useFailureEndpoint = false

    private let baseURL = URL(string: "https://httpbin.org")!

    func runDemo() async {
        if case .loading = state { return }
        state = .loading
        responseHeaders = [:]

        let newRequestId = UUID().uuidString
        requestId = newRequestId

        let requestInterceptor = RequestIdInterceptor(requestId: newRequestId)
        let responseInterceptor = StatusBlockingInterceptor()

        let config = NetworkClientConfiguration(
            baseURL: baseURL,
            requestInterceptors: [requestInterceptor],
            responseInterceptors: [responseInterceptor]
        )

        let client = NetworkClient(configuration: config)
        let path = useFailureEndpoint ? "/status/418" : "/anything"
        let request = Request(method: .get, url: URL(string: path)!, cachePolicy: .ignoreCache)

        do {
            let response = try await client.newCall(request).execute()
            responseHeaders = response.headers.all
            let body = response.body.flatMap { String(data: $0, encoding: .utf8) } ?? "No body"
            state = .success(body: body)
        } catch let error as SampleError {
            state = .failed(error.localizedDescription)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

private struct RequestIdInterceptor: RequestInterceptor {
    let requestId: String

    func interceptRequest(_ request: Request) async throws -> Request {
        var headers = request.headers
        headers["X-Request-ID"] = requestId
        headers["X-SwiftNetwork-Feature"] = "request-interceptor"

        return Request(
            method: request.method,
            url: request.url,
            headers: headers,
            body: request.body,
            timeout: request.timeout,
            cachePolicy: request.cachePolicy,
            priority: request.priority
        )
    }
}

private struct StatusBlockingInterceptor: ResponseInterceptor {
    func interceptResponse(_ response: Response, for request: Request) async throws -> Response {
        if response.statusCode >= 400 {
            throw RequestResponseInterceptorsDemoViewModel.SampleError(statusCode: response.statusCode)
        }

        var headers = response.headers
        headers["X-Processed-By"] = "ResponseInterceptor"

        return Response(
            request: response.request,
            statusCode: response.statusCode,
            headers: headers,
            body: response.body
        )
    }
}
