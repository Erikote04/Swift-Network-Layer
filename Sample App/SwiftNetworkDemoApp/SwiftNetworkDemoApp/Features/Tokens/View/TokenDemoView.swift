//
//  TokenDemoView.swift
//  SwiftNetworkDemo
//
//  View demonstrating token refresh coordination with concurrent requests
//

import SwiftUI

struct TokenDemoView: View {
    
    @State private var viewModel = TokenDemoViewModel()
    @State private var requestCount: Double = 5
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header explanation
                    headerSection
                    
                    // Token status
                    tokenStatusSection
                    
                    // Controls
                    controlsSection
                    
                    // Requests status
                    requestsSection
                    
                    // Event log
                    eventLogSection
                }
                .padding()
            }
            .navigationTitle("Token Demo")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Token Refresh Coordination", systemImage: "lock.shield")
                .font(.headline)
            
            Text("This demo shows how SwiftNetwork handles multiple concurrent requests when the auth token expires. Only ONE token refresh occurs, and all pending requests wait for it.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var tokenStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Current Token", systemImage: "key.fill")
                    .font(.headline)
                Spacer()
            }
            
            if let token = viewModel.currentToken {
                HStack {
                    Text(token)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                HStack {
                    Text("No valid token")
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Circle()
                        .fill(.red)
                        .frame(width: 12, height: 12)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            if viewModel.totalRefreshes > 0 {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Total Refreshes: \(viewModel.totalRefreshes)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var controlsSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Number of Concurrent Requests: \(Int(requestCount))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Slider(value: $requestCount, in: 2...10, step: 1)
                    .disabled(viewModel.isRunning)
            }
            
            HStack(spacing: 12) {
                Button {
                    Task {
                        await viewModel.runDemo(requestCount: Int(requestCount))
                    }
                } label: {
                    HStack {
                        if viewModel.isRunning {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text(viewModel.isRunning ? "Running..." : "Run Demo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isRunning ? Color.gray : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isRunning)
                
                Button {
                    Task {
                        await viewModel.invalidateToken()
                    }
                } label: {
                    Image(systemName: "key.slash")
                        .padding()
                        .background(Color.red.opacity(0.2))
                        .foregroundStyle(.red)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isRunning)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.requests.isEmpty {
                HStack {
                    Label("Requests Status", systemImage: "network")
                        .font(.headline)
                    Spacer()
                }
                
                ForEach(viewModel.requests) { request in
                    RequestCardView(request: request)
                }
            }
        }
    }
    
    private var eventLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.tokenRefreshLog.isEmpty {
                HStack {
                    Label("Event Log", systemImage: "list.bullet.rectangle")
                        .font(.headline)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.tokenRefreshLog, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
}

#Preview {
    TokenDemoView()
}
