//
//  RequestBuilderDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class RequestBuilderDemoViewModel {
    enum State {
        case idle
        case loading
        case loaded([GitHubRepo])
        case failed(String)
    }

    var state: State = .idle

    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    func load() async {
        if case .loading = state { return }
        state = .loading

        var builder = RequestBuilder(
            method: .get,
            url: URL(string: "/search/repositories")!
        )

        let query = "swift language:swift"
        builder
            .queryItem(name: "q", value: query)
            .queryItem(name: "sort", value: "stars")
            .queryItem(name: "order", value: "desc")
            .header("Accept", "application/vnd.github+json")
            .timeout(20)
            .cachePolicy(.ignoreCache)

        let request = builder.build()

        do {
            let response: GitHubSearchResponse = try await client
                .newCall(request)
                .execute(decoder: JSONDecoder())

            state = .loaded(response.items)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

private struct GitHubSearchResponse: Decodable {
    let items: [GitHubRepo]
}
