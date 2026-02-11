//
//  SecurityDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class SecurityDemoViewModel {
    enum State {
        case idle
        case loading
        case success(status: Int, body: String)
        case failed(String)
    }

    var state: State = .idle
    var isPinningEnabled = false

    private let host = "api.github.com"

    func runDemo() async {
        if case .loading = state { return }
        state = .loading

        let baseURL = URL(string: "https://\(host)")!
        let pinner = CertificatePinner(
            pins: [
                host: [
                    .publicKeyHash("sha256/REPLACE_ME_PRIMARY"),
                    .publicKeyHash("sha256/REPLACE_ME_BACKUP")
                ]
            ]
        )

        let config = NetworkClientConfiguration(
            baseURL: baseURL,
            defaultHeaders: ["Accept": "application/vnd.github+json"],
            certificatePinner: isPinningEnabled ? pinner : nil
        )

        let client = NetworkClient(configuration: config)
        let request = Request(
            method: .get,
            url: URL(string: "/zen")!,
            cachePolicy: .ignoreCache
        )

        do {
            let response = try await client.newCall(request).execute()
            let body = response.body.flatMap { String(data: $0, encoding: .utf8) } ?? "No body"
            state = .success(status: response.statusCode, body: body)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    var instructions: [String] {
        [
            "Replace the placeholder pins with real SHA-256 hashes.",
            "Pin at least two keys (primary + backup).",
            "Use public key pinning so certificate rotation does not break clients.",
            "Keep pins per host in your production configuration."
        ]
    }
}
