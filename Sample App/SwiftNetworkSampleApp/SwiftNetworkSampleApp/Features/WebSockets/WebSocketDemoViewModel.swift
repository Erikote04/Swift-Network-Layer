//
//  WebSocketDemoViewModel.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

@MainActor
@Observable
final class WebSocketDemoViewModel {
    enum ConnectionState: String {
        case disconnected = "Disconnected"
        case connecting = "Connecting"
        case connected = "Connected"
        case closing = "Closing"
    }

    struct Message: Identifiable, Hashable {
        let id = UUID()
        let direction: Direction
        let payload: String
        let timestamp: Date

        enum Direction: String {
            case sent = "Sent"
            case received = "Received"
            case system = "System"
        }
    }

    var state: ConnectionState = .disconnected
    var messageInput: String = "Hello from SwiftNetwork"
    var messages: [Message] = []
    var lastError: String?

    private var transport: WebSocketTransport?
    private var receiveTask: Task<Void, Never>?

    func connect(using client: NetworkClient) async {
        guard state == .disconnected else { return }
        state = .connecting
        lastError = nil

        let url = URL(string: "https://echo.websocket.events")!
        let request = Request(method: .get, url: url)
        let call = client.newWebSocketCall(request)

        do {
            let transport = try await call.connect()
            self.transport = transport
            transport.enableConnectionMonitoring(pingInterval: 20, pongTimeout: 8)
            await transport.enableAutoReconnect(maxAttempts: 3)

            let urlString = await transport.url.absoluteString
            state = .connected
            appendSystemMessage("Connected to \(urlString)")
            startReceivingMessages(from: transport)
        } catch {
            state = .disconnected
            lastError = error.localizedDescription
            appendSystemMessage("Failed to connect: \(error.localizedDescription)")
        }
    }

    func disconnect() async {
        guard let transport, state == .connected else { return }
        state = .closing
        receiveTask?.cancel()
        receiveTask = nil

        await transport.close(code: .normalClosure, reason: "User disconnected")
        self.transport = nil
        state = .disconnected
        appendSystemMessage("Disconnected")
    }

    func sendMessage() async {
        guard let transport, state == .connected else { return }
        let trimmed = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            try await transport.send(.text(trimmed))
            appendMessage(.sent, trimmed)
            messageInput = ""
        } catch {
            lastError = error.localizedDescription
            appendSystemMessage("Send failed: \(error.localizedDescription)")
        }
    }

    private func startReceivingMessages(from transport: WebSocketTransport) {
        receiveTask?.cancel()
        receiveTask = Task {
            for await message in await transport.messages {
                switch message {
                case .text(let text):
                    await MainActor.run {
                        self.appendMessage(.received, text)
                    }
                case .binary(let data):
                    await MainActor.run {
                        self.appendMessage(.received, "Binary (\(data.count) bytes)")
                    }
                }
            }
        }
    }

    private func appendMessage(_ direction: Message.Direction, _ payload: String) {
        messages.append(Message(direction: direction, payload: payload, timestamp: Date()))
        trimMessagesIfNeeded()
    }

    private func appendSystemMessage(_ payload: String) {
        messages.append(Message(direction: .system, payload: payload, timestamp: Date()))
        trimMessagesIfNeeded()
    }

    private func trimMessagesIfNeeded() {
        if messages.count > 50 {
            messages.removeFirst(messages.count - 50)
        }
    }
}
