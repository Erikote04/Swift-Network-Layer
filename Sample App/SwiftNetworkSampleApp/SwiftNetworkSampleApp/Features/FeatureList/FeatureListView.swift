//
//  FeatureListView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI
import SwiftNetwork

struct FeatureListView: View {
    let client: NetworkClient

    var body: some View {
        List {
            Section("Core") {
                NavigationLink(value: Feature.repos) {
                    FeatureRow(title: "Repository List", subtitle: "Basic GET + decoding")
                }
                NavigationLink(value: Feature.requestBuilder) {
                    FeatureRow(title: "Request Builder", subtitle: "Headers + timeout + query")
                }
                NavigationLink(value: Feature.caching) {
                    FeatureRow(title: "Caching", subtitle: "Memory, disk, and hybrid cache")
                }
            }
        }
        .navigationTitle("SwiftNetwork Samples")
        .navigationDestination(for: Feature.self) { feature in
            switch feature {
            case .repos:
                RepoListView(client: client)
            case .requestBuilder:
                RequestBuilderDemoView(client: client)
            case .caching:
                CacheDemoView()
            }
        }
    }
}

private enum Feature: Hashable {
    case repos
    case requestBuilder
    case caching
}

private struct FeatureRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        FeatureListView(client: NetworkClient())
    }
}
