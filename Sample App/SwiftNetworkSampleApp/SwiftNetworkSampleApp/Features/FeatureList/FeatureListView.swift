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
    @State private var sortOrder: FeatureSortOrder = .alphabetical

    var body: some View {
        List {
            Section("Features") {
                ForEach(sortedFeatures, id: \.feature) { item in
                    NavigationLink(value: item.feature) {
                        FeatureRow(title: item.title, subtitle: item.subtitle)
                    }
                }
            }
        }
        .navigationTitle("SwiftNetwork Samples")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(FeatureSortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            Label(order.title, systemImage: order.symbolName)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
        }
        .navigationDestination(for: Feature.self) { feature in
            switch feature {
            case .repos:
                RepoListView(client: client)
            case .requestBuilder:
                RequestBuilderDemoView(client: client)
            case .caching:
                CacheDemoView()
            case .interceptors:
                InterceptorsDemoView()
            case .requestResponseInterceptors:
                RequestResponseInterceptorsDemoView()
            case .retry:
                RetryDemoView()
            case .multipart:
                MultipartDemoView()
            case .requestBodies:
                RequestBodyDemoView()
            case .progress:
                ProgressDemoView(client: client)
            case .streaming:
                StreamingDemoView(client: client)
            case .metrics:
                MetricsDemoView()
            case .webSockets:
                WebSocketDemoView(client: client)
            case .performance:
                PerformanceDemoView()
            case .security:
                SecurityDemoView()
            case .auth:
                AuthDemoView()
            case .appleSignIn:
                AppleSignInView()
            }
        }
    }

    private var sortedFeatures: [FeatureItem] {
        switch sortOrder {
        case .alphabetical:
            return featureItems.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .easeToAdvanced:
            return featureItems.sorted { $0.difficulty < $1.difficulty }
        }
    }
}

private enum Feature: Hashable {
    case repos
    case requestBuilder
    case caching
    case interceptors
    case requestResponseInterceptors
    case retry
    case multipart
    case requestBodies
    case progress
    case streaming
    case metrics
    case webSockets
    case performance
    case security
    case auth
    case appleSignIn
}

private enum FeatureSortOrder: CaseIterable {
    case alphabetical
    case easeToAdvanced

    var title: String {
        switch self {
        case .alphabetical:
            return "Alphabetical"
        case .easeToAdvanced:
            return "Increasing Difficulty"
        }
    }

    var symbolName: String {
        switch self {
        case .alphabetical:
            return "textformat.characters.arrow.left.and.right"
        case .easeToAdvanced:
            return "arrow.up.right"
        }
    }
}

private struct FeatureItem: Hashable {
    let feature: Feature
    let title: String
    let subtitle: String
    let difficulty: Int
}

private let featureItems: [FeatureItem] = [
    FeatureItem(feature: .appleSignIn, title: "Apple Sign-In", subtitle: "Sign in with Apple flow", difficulty: 7),
    FeatureItem(feature: .auth, title: "Auth", subtitle: "TokenStore + AuthInterceptor", difficulty: 3),
    FeatureItem(feature: .caching, title: "Caching", subtitle: "Memory, disk, and hybrid cache", difficulty: 4),
    FeatureItem(feature: .interceptors, title: "Interceptors", subtitle: "Conditional + prioritized header", difficulty: 4),
    FeatureItem(feature: .metrics, title: "Metrics", subtitle: "Aggregate request statistics", difficulty: 4),
    FeatureItem(feature: .multipart, title: "Multipart", subtitle: "Multipart upload + progress", difficulty: 5),
    FeatureItem(feature: .performance, title: "Performance", subtitle: "Deduplication + priority", difficulty: 6),
    FeatureItem(feature: .progress, title: "Progress", subtitle: "Upload progress callbacks", difficulty: 4),
    FeatureItem(feature: .repos, title: "Repository List", subtitle: "Basic GET + decoding", difficulty: 1),
    FeatureItem(feature: .requestBodies, title: "Request Bodies", subtitle: "JSON, form, raw data", difficulty: 2),
    FeatureItem(feature: .requestBuilder, title: "Request Builder", subtitle: "Headers + timeout + query", difficulty: 2),
    FeatureItem(feature: .requestResponseInterceptors, title: "Req/Res Interceptors", subtitle: "Request + response interceptors", difficulty: 5),
    FeatureItem(feature: .retry, title: "Retry", subtitle: "Automatic retries with metrics", difficulty: 5),
    FeatureItem(feature: .security, title: "Security", subtitle: "Certificate pinning", difficulty: 6),
    FeatureItem(feature: .streaming, title: "Streaming", subtitle: "Incremental response stream", difficulty: 5),
    FeatureItem(feature: .webSockets, title: "WebSockets", subtitle: "Connect, send, and receive", difficulty: 6)
]

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
