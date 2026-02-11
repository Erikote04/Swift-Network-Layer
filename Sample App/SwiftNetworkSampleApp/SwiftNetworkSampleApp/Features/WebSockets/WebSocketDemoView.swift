//
//  WebSocketDemoView.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import SwiftUI
import SwiftNetwork

struct WebSocketDemoView: View {
    let client: NetworkClient
    @State private var viewModel = WebSocketDemoViewModel()

    var body: some View {
        List {
            connectionSection
            sendSection
            messagesSection
        }
        .navigationTitle("WebSockets")
    }

    private var connectionSection: some View {
        Section("Connection") {
            HStack {
                Text("Status")
                Spacer()
                Text(viewModel.state.rawValue)
                    .foregroundStyle(statusColor)
            }

            Text("Echo server: https://echo.websocket.events")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let lastError = viewModel.lastError {
                Text(lastError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Connect") {
                    Task { await viewModel.connect(using: client) }
                }
                .disabled(viewModel.state != .disconnected)

                Spacer()

                Button("Disconnect") {
                    Task { await viewModel.disconnect() }
                }
                .disabled(viewModel.state != .connected)
                .foregroundStyle(.red)
            }
        }
    }

    private var sendSection: some View {
        Section("Send Message") {
            TextField("Message", text: $viewModel.messageInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("Send") {
                Task { await viewModel.sendMessage() }
            }
            .disabled(viewModel.state != .connected)
        }
    }

    private var messagesSection: some View {
        Section("Messages") {
            if viewModel.messages.isEmpty {
                Text("No messages yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.messages) { message in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(message.direction.rawValue)
                                .font(.caption)
                                .foregroundStyle(directionColor(message.direction))
                            Spacer()
                            Text(message.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text(message.payload)
                            .font(.callout)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var statusColor: Color {
        switch viewModel.state {
        case .disconnected:
            return .secondary
        case .connecting:
            return .orange
        case .connected:
            return .green
        case .closing:
            return .red
        }
    }

    private func directionColor(_ direction: WebSocketDemoViewModel.Message.Direction) -> Color {
        switch direction {
        case .sent:
            return .blue
        case .received:
            return .green
        case .system:
            return .orange
        }
    }
}

#Preview {
    NavigationStack {
        WebSocketDemoView(client: NetworkClient())
    }
}
