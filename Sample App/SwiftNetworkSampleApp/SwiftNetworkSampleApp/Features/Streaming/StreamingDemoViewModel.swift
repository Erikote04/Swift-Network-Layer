//
//  StreamingDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class StreamingDemoViewModel {
    enum State {
        case idle
        case streaming(bytes: Int, chunks: Int)
        case completed(bytes: Int, chunks: Int)
        case failed(String)
    }

    var state: State = .idle

    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    func startStreaming() async {
        state = .streaming(bytes: 0, chunks: 0)

        let request = Request(
            method: .get,
            url: URL(string: "https://httpbin.org/bytes/65536")!,
            cachePolicy: .ignoreCache
        )

        guard let streamingCall = client.newCall(request) as? StreamingCall else {
            state = .failed("StreamingCall not supported")
            return
        }

        var totalBytes = 0
        var chunkCount = 0

        do {
            for try await chunk in streamingCall.stream() {
                totalBytes += chunk.count
                chunkCount += 1

                let currentBytes = totalBytes
                let currentChunks = chunkCount
                await MainActor.run {
                    state = .streaming(bytes: currentBytes, chunks: currentChunks)
                }
            }

            state = .completed(bytes: totalBytes, chunks: chunkCount)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
