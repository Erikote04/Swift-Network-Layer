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
                Text("Request #\(request.requestNumber)")
                    .font(.headline)
                
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
                .stroke(borderColor, lineWidth: 1)
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
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.orange)
                    .symbolEffect(.rotate, options: .repeating)
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
        case .executing, .refreshingToken:
            return Color.blue.opacity(0.05)
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
        case .executing, .refreshingToken:
            return Color.blue.opacity(0.3)
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
