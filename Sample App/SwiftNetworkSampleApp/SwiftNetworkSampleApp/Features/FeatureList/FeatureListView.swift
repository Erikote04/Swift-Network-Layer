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
                NavigationLink(value: Feature.interceptors) {
                    FeatureRow(title: "Interceptors", subtitle: "Conditional + prioritized header")
                }
                NavigationLink(value: Feature.requestResponseInterceptors) {
                    FeatureRow(title: "Req/Res Interceptors", subtitle: "Request + response interceptors")
                }
                NavigationLink(value: Feature.retry) {
                    FeatureRow(title: "Retry", subtitle: "Automatic retries with metrics")
                }
                NavigationLink(value: Feature.multipart) {
                    FeatureRow(title: "Multipart", subtitle: "Multipart upload + progress")
                }
                NavigationLink(value: Feature.progress) {
                    FeatureRow(title: "Progress", subtitle: "Upload progress callbacks")
                }
                NavigationLink(value: Feature.streaming) {
                    FeatureRow(title: "Streaming", subtitle: "Incremental response stream")
                }
                NavigationLink(value: Feature.metrics) {
                    FeatureRow(title: "Metrics", subtitle: "Aggregate request statistics")
                }
                NavigationLink(value: Feature.webSockets) {
                    FeatureRow(title: "WebSockets", subtitle: "Connect, send, and receive")
                }
                NavigationLink(value: Feature.performance) {
                    FeatureRow(title: "Performance", subtitle: "Deduplication + priority")
                }
                NavigationLink(value: Feature.security) {
                    FeatureRow(title: "Security", subtitle: "Certificate pinning")
                }
                NavigationLink(value: Feature.auth) {
                    FeatureRow(title: "Auth", subtitle: "TokenStore + AuthInterceptor")
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
            case .interceptors:
                InterceptorsDemoView()
            case .requestResponseInterceptors:
                RequestResponseInterceptorsDemoView()
            case .retry:
                RetryDemoView()
            case .multipart:
                MultipartDemoView()
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
            }
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
    case progress
    case streaming
    case metrics
    case webSockets
    case performance
    case security
    case auth
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
