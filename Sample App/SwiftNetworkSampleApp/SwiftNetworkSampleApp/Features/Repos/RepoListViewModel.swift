//
//  RepoListViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class RepoListViewModel {
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

        let request = Request(
            method: .get,
            url: URL(string: "/orgs/apple/repos")!
        )

        do {
            let repos: [GitHubRepo] = try await client
                .newCall(request)
                .execute(decoder: JSONDecoder())

            state = .loaded(repos.sorted { $0.stargazersCount > $1.stargazersCount })
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
