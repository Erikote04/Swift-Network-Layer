//
//  MultipartDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class MultipartDemoViewModel {
    enum State {
        case idle
        case uploading
        case success(String)
        case failed(String)
    }

    var state: State = .idle
    var uploadProgress: Double = 0

    private let baseURL = URL(string: "https://httpbin.org")!

    func uploadSample() async {
        if case .uploading = state { return }
        state = .uploading
        uploadProgress = 0

        let parts = buildMultipart()
        let request = Request(
            method: .post,
            url: URL(string: "/post")!,
            body: .multipart(parts),
            cachePolicy: .ignoreCache
        )

        let client = NetworkClient(configuration: NetworkClientConfiguration(baseURL: baseURL))

        do {
            let call = client.makeCall(request)
            guard let progressCall = call as? ProgressCall else {
                state = .failed("Progress reporting is unavailable for this request.")
                return
            }

            let progressAccumulator = ProgressAccumulator()
            let progressStream = await progressAccumulator.stream()
            let progressTask = Task { @MainActor [weak self] in
                for await value in progressStream {
                    self?.uploadProgress = value
                }
            }

            defer {
                Task { await progressAccumulator.finish() }
                progressTask.cancel()
            }

            let response = try await progressCall.execute { progress in
                Task { await progressAccumulator.update(progress.fractionCompleted) }
            }

            let body = response.body.flatMap { String(data: $0, encoding: .utf8) } ?? "No body"
            state = .success(body)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func buildMultipart() -> [MultipartFormData] {
        let note = MultipartFormData(name: "note", value: "SwiftNetwork multipart upload demo")
        let metadata = MultipartFormData(
            name: "metadata",
            value: "{\"source\":\"sample-app\",\"type\":\"text\"}"
        )

        let fileBytes = "Hello from SwiftNetwork".data(using: .utf8) ?? Data()
        let filePart = MultipartFormData(
            name: "file",
            filename: "greeting.txt",
            data: fileBytes,
            mimeType: "text/plain"
        )

        return [note, metadata, filePart]
    }
}

private actor ProgressAccumulator {
    private var continuation: AsyncStream<Double>.Continuation?

    func stream() -> AsyncStream<Double> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func update(_ value: Double) {
        continuation?.yield(value)
    }

    func finish() {
        continuation?.finish()
        continuation = nil
    }
}
