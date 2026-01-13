//
//  RequestCardView.swift
//  SwiftNetworkDemo
//
//  Card component for displaying individual request status
//

import SwiftUI

struct RequestCardView: View {
    
    let request: RequestState
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon
                .frame(width: 40, height: 40)
            
            // Request info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Request #\(request.requestNumber)")
                        .font(.headline)
                    
                    // Special badge for the request refreshing the token
                    if request.isRefreshingToken && request.status == .refreshingToken {
                        Text("REFRESHING TOKEN")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.orange)
                            )
                    }
                }
                
                Text(request.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Timestamp
            Text(request.timestamp.formatted(date: .omitted, time: .standard))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: request.isRefreshingToken ? 2 : 1)
        )
    }
    
    // MARK: - Computed Properties
    
    @ViewBuilder
    private var statusIcon: some View {
        switch request.status {
        case .waiting:
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                Image(systemName: "clock")
                    .foregroundStyle(.gray)
            }
            
        case .executing:
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                ProgressView()
                    .tint(.blue)
            }
            
        case .refreshingToken:
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .overlay(
                        Circle()
                            .stroke(Color.orange, lineWidth: 3)
                            .scaleEffect(request.isRefreshingToken ? 1.2 : 1.0)
                            .opacity(request.isRefreshingToken ? 0 : 1)
                            .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: request.isRefreshingToken)
                    )
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.orange)
                    .fontWeight(.bold)
                    .symbolEffect(.rotate, options: .repeating)
            }
            
        case .waitingForToken:
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                Image(systemName: "hourglass")
                    .foregroundStyle(.purple)
                    .symbolEffect(.pulse, options: .repeating)
            }
            
        case .success:
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                Image(systemName: "checkmark")
                    .foregroundStyle(.green)
                    .fontWeight(.bold)
            }
            
        case .failed:
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                Image(systemName: "xmark")
                    .foregroundStyle(.red)
                    .fontWeight(.bold)
            }
        }
    }
    
    private var backgroundColor: Color {
        switch request.status {
        case .waiting:
            return Color(.systemGray6)
        case .executing:
            return Color.blue.opacity(0.05)
        case .refreshingToken:
            return request.isRefreshingToken ? Color.orange.opacity(0.15) : Color.orange.opacity(0.05)
        case .waitingForToken:
            return Color.purple.opacity(0.05)
        case .success:
            return Color.green.opacity(0.05)
        case .failed:
            return Color.red.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        switch request.status {
        case .waiting:
            return Color.gray.opacity(0.3)
        case .executing:
            return Color.blue.opacity(0.3)
        case .refreshingToken:
            return request.isRefreshingToken ? Color.orange : Color.orange.opacity(0.3)
        case .waitingForToken:
            return Color.purple.opacity(0.3)
        case .success:
            return Color.green.opacity(0.3)
        case .failed:
            return Color.red.opacity(0.3)
        }
    }
}

#Preview("Waiting") {
    RequestCardView(
        request: RequestState(requestNumber: 1)
    )
    .padding()
}

#Preview("Executing") {
    var state = RequestState(requestNumber: 2)
    state.updateStatus(.executing, message: "Executing request...")
    
    return RequestCardView(request: state)
        .padding()
}

#Preview("Success") {
    var state = RequestState(requestNumber: 3)
    state.updateStatus(.success, message: "Request completed successfully!")
    
    return RequestCardView(request: state)
        .padding()
}

#Preview("Failed") {
    var state = RequestState(requestNumber: 4)
    state.updateStatus(.failed, message: "Request failed with error")
    
    return RequestCardView(request: state)
        .padding()
}
