//
//  ProgressDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class ProgressDemoViewModel {
    enum State {
        case idle
        case uploading(Double)
        case completed(String)
        case failed(String)
    }

    var state: State = .idle

    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    func upload() async {
        state = .uploading(0)

        let data = Data(repeating: 0xFF, count: 1024 * 128)
        let request = Request(
            method: .post,
            url: URL(string: "https://httpbin.org/post")!,
            body: .data(data, contentType: "application/octet-stream"),
            cachePolicy: .ignoreCache
        )

        let call = client.newCall(request)
        guard let progressCall = call as? ProgressCall else {
            state = .failed("ProgressCall not supported")
            return
        }

        do {
            let response = try await progressCall.execute { progress in
                let fraction = progress.fractionCompleted
                Task { @MainActor in
                    self.state = .uploading(fraction)
                }
            }

            let message = "Upload complete (status \(response.statusCode))"
            state = .completed(message)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
