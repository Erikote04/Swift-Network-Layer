//
//  WebSocketConnectionMonitor.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 28/1/26.
//

import Foundation

/// Monitors WebSocket connection health and detects connection issues.
///
/// `WebSocketConnectionMonitor` implements a ping/pong heartbeat mechanism
/// to detect stale connections and trigger reconnection if needed.
///
/// The monitor sends periodic ping frames and expects pong responses.
/// If a pong is not received within the timeout period, the connection
/// is considered unhealthy and can be terminated.
public actor WebSocketConnectionMonitor {
    
    // MARK: - Configuration
    
    /// The interval between ping frames.
    nonisolated public let pingInterval: TimeInterval
    
    /// The maximum time to wait for a pong response.
    nonisolated public let pongTimeout: TimeInterval
    
    // MARK: - State
    
    /// Whether the monitor is currently running.
    private var isRunning = false
    
    /// The task handling the monitoring loop.
    private var monitorTask: Task<Void, Never>?
    
    /// The last time a pong was received.
    private var lastPongTime: Date?
    
    /// Callback to invoke when connection health changes.
    private var healthCallback: (@Sendable (Bool) async -> Void)?
    
    // MARK: - Initialization
    
    /// Creates a new connection monitor.
    ///
    /// - Parameters:
    ///   - pingInterval: How often to send ping frames (default: 30 seconds).
    ///   - pongTimeout: Maximum time to wait for pong response (default: 10 seconds).
    public init(
        pingInterval: TimeInterval = 30.0,
        pongTimeout: TimeInterval = 10.0
    ) {
        self.pingInterval = pingInterval
        self.pongTimeout = pongTimeout
    }
    
    // MARK: - Control
    
    /// Starts monitoring the connection.
    ///
    /// The monitor will send periodic ping frames and check for pong responses.
    /// If a pong is not received within the timeout, the health callback is
    /// invoked with `false`.
    ///
    /// - Parameters:
    ///   - sendPing: A closure that sends a ping frame.
    ///   - onHealthChange: A callback invoked when connection health changes.
    public func start(
        sendPing: @escaping @Sendable () async throws -> Void,
        onHealthChange: @escaping @Sendable (Bool) async -> Void
    ) {
        guard !isRunning else { return }
        
        isRunning = true
        healthCallback = onHealthChange
        lastPongTime = Date()
        
        monitorTask = Task {
            while !Task.isCancelled && isRunning {
                // Wait for the ping interval
                try? await Task.sleep(nanoseconds: UInt64(pingInterval * 1_000_000_000))
                
                guard !Task.isCancelled && isRunning else { break }
                
                // Send ping
                do {
                    try await sendPing()
                } catch {
                    // Ping failed - connection might be dead
                    await onHealthChange(false)
                    break
                }
                
                // Wait for pong timeout
                try? await Task.sleep(nanoseconds: UInt64(pongTimeout * 1_000_000_000))
                
                // Check if pong was received
                if let lastPong = lastPongTime,
                   Date().timeIntervalSince(lastPong) > pongTimeout + pingInterval {
                    // No pong received - connection is unhealthy
                    await onHealthChange(false)
                    break
                }
            }
        }
    }
    
    /// Stops monitoring the connection.
    public func stop() {
        isRunning = false
        monitorTask?.cancel()
        monitorTask = nil
    }
    
    /// Notifies the monitor that a pong was received.
    ///
    /// This should be called when a pong frame is received from the server.
    public func receivedPong() {
        lastPongTime = Date()
    }
    
    /// Whether the monitor is currently running.
    public var running: Bool {
        isRunning
    }
}
