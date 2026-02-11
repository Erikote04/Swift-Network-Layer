//
//  RequestBodyDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class RequestBodyDemoViewModel {
    enum BodyKind: String, CaseIterable, Identifiable {
        case json = "JSON"
        case form = "Form URL-Encoded"
        case data = "Raw Data"

        var id: String { rawValue }
    }

    enum State {
        case idle
        case loading
        case success(String)
        case failed(String)
    }

    struct NotePayload: Encodable, Sendable {
        let title: String
        let message: String
        let count: Int
    }

    var selectedKind: BodyKind = .json
    var state: State = .idle

    private let baseURL = URL(string: "https://httpbin.org")!

    func send() async {
        if case .loading = state { return }
        state = .loading

        let client = NetworkClient(configuration: NetworkClientConfiguration(baseURL: baseURL))
        let request: Request

        switch selectedKind {
        case .json:
            let payload = NotePayload(title: "SwiftNetwork", message: "JSON body demo", count: 3)
            request = Request(
                method: .post,
                url: URL(string: "/post")!,
                body: .json(payload),
                cachePolicy: .ignoreCache
            )

        case .form:
            let fields: [String: String] = [
                "email": "dev@example.com",
                "plan": "pro",
                "active": "true"
            ]
            request = Request(
                method: .post,
                url: URL(string: "/post")!,
                body: .form(fields),
                cachePolicy: .ignoreCache
            )

        case .data:
            let rawString = "Raw body from SwiftNetwork"
            let data = Data(rawString.utf8)
            request = Request(
                method: .post,
                url: URL(string: "/post")!,
                body: .data(data, contentType: "text/plain; charset=utf-8"),
                cachePolicy: .ignoreCache
            )
        }

        do {
            let response = try await client.newCall(request).execute()
            let body = response.body.flatMap { String(data: $0, encoding: .utf8) } ?? "No body"
            state = .success(body)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
