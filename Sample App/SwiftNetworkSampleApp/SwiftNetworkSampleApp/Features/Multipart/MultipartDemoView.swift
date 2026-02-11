//
//  MultipartDemoView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI

struct MultipartDemoView: View {
    @State private var viewModel = MultipartDemoViewModel()

    var body: some View {
        List {
            uploadSection
            progressSection
            resultSection
        }
        .navigationTitle("Multipart Upload")
    }

    private var uploadSection: some View {
        Section("Upload") {
            Text("Uploads a multipart/form-data request with text fields and a file using httpbin.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Upload Sample") {
                Task { await viewModel.uploadSample() }
            }
            .disabled(viewModel.isUploading)
        }
    }

    private var progressSection: some View {
        Section("Progress") {
            ProgressView(value: viewModel.uploadProgress)
            Text("\(Int(viewModel.uploadProgress * 100))%")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        Section("Result") {
            switch viewModel.state {
            case .idle:
                Text("No upload yet")
                    .foregroundStyle(.secondary)
            case .uploading:
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Uploading...")
                }
            case .success(let body):
                Text(body)
                    .font(.footnote)
                    .textSelection(.enabled)
            case .failed(let message):
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upload failed")
                        .font(.headline)
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private extension MultipartDemoViewModel {
    var isUploading: Bool {
        if case .uploading = state { return true }
        return false
    }
}

#Preview {
    NavigationStack {
        MultipartDemoView()
    }
}
