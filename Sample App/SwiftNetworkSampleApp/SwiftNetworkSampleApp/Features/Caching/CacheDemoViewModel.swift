//
//  CacheDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class CacheDemoViewModel {
    enum CacheType: String, CaseIterable, Identifiable {
        case memory = "Memory"
        case disk = "Disk"
        case hybrid = "Hybrid"

        var id: String { rawValue }
    }

    enum State {
        case idle
        case loading
        case loaded([GitHubRepo], cacheResult: String)
        case failed(String)
    }

    var state: State = .idle
    var selectedCache: CacheType = .memory
    var policy: CachePolicy = .useCache

    private let baseURL = URL(string: "https://api.github.com")!
    private let metrics = CacheMetricsCollector()

    private var memoryCache = ResponseCache(ttl: 60)
    private var diskCache: DiskCacheStorage?
    private var hybridCache: HybridCacheStorage?

    init() {
        diskCache = try? DiskCacheStorage(directory: "sample-cache", ttl: 600)
        hybridCache = try? HybridCacheStorage(memoryCapacity: 50, diskDirectory: "sample-cache", ttl: 600)
    }

    func load() async {
        if case .loading = state { return }
        state = .loading

        await metrics.reset()

        let request = Request(
            method: .get,
            url: URL(string: "/orgs/apple/repos")!,
            cachePolicy: policy
        )

        do {
            let client = try configuredClient()
            let response = try await client.newCall(request).execute()

            let decoder = JSONDecoder()
            let repos = try decoder.decode([GitHubRepo].self, from: response.body ?? Data())

            let cacheResult = await metrics.latestResult()?.rawValue ?? "unknown"
            state = .loaded(repos.sorted { $0.stargazersCount > $1.stargazersCount }, cacheResult: cacheResult)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func clearCache() async {
        switch selectedCache {
        case .memory:
            memoryCache = ResponseCache(ttl: 60)
        case .disk:
            await diskCache?.clearAll()
        case .hybrid:
            await hybridCache?.clearAll()
        }
    }

    private func configuredClient() throws -> NetworkClient {
        let cacheInterceptor: CacheInterceptor
        switch selectedCache {
        case .memory:
            cacheInterceptor = CacheInterceptor(cache: memoryCache, metrics: metrics)
        case .disk:
            guard let diskCache else {
                throw CacheDemoError.storageUnavailable("Disk cache unavailable")
            }
            cacheInterceptor = CacheInterceptor(cache: diskCache, metrics: metrics)
        case .hybrid:
            guard let hybridCache else {
                throw CacheDemoError.storageUnavailable("Hybrid cache unavailable")
            }
            cacheInterceptor = CacheInterceptor(cache: hybridCache, metrics: metrics)
        }

        let config = NetworkClientConfiguration(
            baseURL: baseURL,
            defaultHeaders: ["Accept": "application/vnd.github+json"],
            timeout: 30,
            interceptors: [cacheInterceptor]
        )

        return NetworkClient(configuration: config)
    }
}

enum CacheDemoError: LocalizedError {
    case storageUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .storageUnavailable(let message):
            return message
        }
    }
}
