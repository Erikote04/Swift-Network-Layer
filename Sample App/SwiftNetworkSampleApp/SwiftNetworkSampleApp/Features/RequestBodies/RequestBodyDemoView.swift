//
//  RequestBodyDemoView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI

struct RequestBodyDemoView: View {
    @State private var viewModel = RequestBodyDemoViewModel()

    var body: some View {
        List {
            controlsSection
            resultSection
        }
        .navigationTitle("Request Bodies")
    }

    private var controlsSection: some View {
        Section("Body Type") {
            Picker("Body Type", selection: $viewModel.selectedKind) {
                ForEach(RequestBodyDemoViewModel.BodyKind.allCases) { kind in
                    Text(kind.rawValue).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            Button("Send Request") {
                Task { await viewModel.send() }
            }
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        Section("Result") {
            switch viewModel.state {
            case .idle:
                Text("No request yet")
                    .foregroundStyle(.secondary)
            case .loading:
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Sending...")
                }
            case .success(let body):
                Text(body)
                    .font(.footnote)
                    .textSelection(.enabled)
            case .failed(let message):
                VStack(alignment: .leading, spacing: 8) {
                    Text("Request failed")
                        .font(.headline)
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RequestBodyDemoView()
    }
}
