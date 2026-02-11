//
//  AuthDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class AuthDemoViewModel {
    enum State {
        case idle
        case loading
        case loaded(String)
        case failed(String)
    }

    var state: State = .idle
    var tokenInput: String = ""

    private let tokenStore: KeychainTokenStore

    init() {
        tokenStore = KeychainTokenStore(service: "com.erikote04.swiftnetwork.sample")
    }

    func loadToken() async {
        tokenInput = await tokenStore.currentToken() ?? ""
    }

    func saveToken() async {
        await tokenStore.updateToken(tokenInput)
    }

    func clearToken() async {
        await tokenStore.updateToken("")
        tokenInput = ""
    }

    func fetchProfile() async {
        if case .loading = state { return }
        state = .loading

        let authInterceptor = AuthInterceptor(tokenStore: tokenStore)
        let config = NetworkClientConfiguration(
            baseURL: URL(string: "https://api.github.com")!,
            defaultHeaders: [
                "Accept": "application/vnd.github+json"
            ],
            timeout: 20,
            interceptors: [authInterceptor]
        )

        let client = NetworkClient(configuration: config)
        let request = Request(method: .get, url: URL(string: "/user")!, cachePolicy: .ignoreCache)

        do {
            let response = try await client.newCall(request).execute()
            let body = response.body.flatMap { String(data: $0, encoding: .utf8) } ?? "No body"
            state = .loaded(body)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

}
