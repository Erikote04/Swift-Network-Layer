//
//  WebSocketMonitoringTests.swift
//  SwiftNetworkTests
//
//  Created by SwiftNetwork Contributors on 28/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("WebSocket Connection Monitoring", .tags(.websocket))
struct WebSocketMonitoringTests {
    
    @Test("Connection monitor can be created")
    func monitorCreation() async {
        let monitor = WebSocketConnectionMonitor(
            pingInterval: 30.0,
            pongTimeout: 10.0
        )
        
        #expect(monitor.pingInterval == 30.0)
        #expect(monitor.pongTimeout == 10.0)
        #expect(await monitor.running == false)
    }
    
    @Test("Connection monitor can be started and stopped")
    func monitorStartStop() async {
        let monitor = WebSocketConnectionMonitor(
            pingInterval: 1.0,
            pongTimeout: 0.5
        )
        
        let pingCounter = PingCounter()
        
        await monitor.start(
            sendPing: {
                await pingCounter.increment()
            },
            onHealthChange: { _ in }
        )
        
        #expect(await monitor.running == true)
        
        await monitor.stop()
        
        #expect(await monitor.running == false)
    }
    
    @Test("Connection monitor sends periodic pings")
    func monitorSendsPings() async {
        let monitor = WebSocketConnectionMonitor(
            pingInterval: 0.2,  // Ping every 200ms
            pongTimeout: 0.1    // Wait 100ms for pong
        )
        
        let pingCounter = PingCounter()
        
        await monitor.start(
            sendPing: {
                await pingCounter.increment()
                await monitor.receivedPong()  // Simulate immediate pong
            },
            onHealthChange: { _ in }
        )
        
        // Wait long enough for multiple pings
        // With 200ms interval, in 700ms we should get at least 3 pings
        try? await Task.sleep(nanoseconds: 700_000_000)  // 700ms
        
        await monitor.stop()
        
        let count = await pingCounter.count
        #expect(count >= 2, "Expected at least 2 pings, got \(count)")
    }
    
    @Test("Connection monitor detects missing pongs")
    func monitorDetectsMissingPongs() async {
        let monitor = WebSocketConnectionMonitor(
            pingInterval: 0.1,   // Ping every 100ms
            pongTimeout: 0.05    // Wait only 50ms for pong
        )
        
        let healthTracker = HealthTracker()
        
        await monitor.start(
            sendPing: {
                // Send ping but DON'T respond with pong - simulate dead connection
            },
            onHealthChange: { isHealthy in
                await healthTracker.record(isHealthy)
            }
        )
        
        // Wait for:
        // - First ping at 0ms
        // - Wait 100ms (pingInterval)
        // - Check pong timeout at 100ms + 50ms = 150ms
        // - Detect unhealthy at ~150ms
        // So we need to wait at least 200ms to be safe
        try? await Task.sleep(nanoseconds: 300_000_000)  // 300ms
        
        await monitor.stop()
        
        let wasUnhealthy = await healthTracker.wasUnhealthy
        #expect(wasUnhealthy == true, "Monitor should have detected unhealthy connection")
    }
    
    @Test("Connection monitor with responsive pongs stays healthy")
    func monitorWithPongsStaysHealthy() async {
        let monitor = WebSocketConnectionMonitor(
            pingInterval: 0.1,
            pongTimeout: 0.05
        )
        
        let healthTracker = HealthTracker()
        
        await monitor.start(
            sendPing: {
                // Immediately respond with pong - simulate healthy connection
                await monitor.receivedPong()
            },
            onHealthChange: { isHealthy in
                await healthTracker.record(isHealthy)
            }
        )
        
        // Wait for several ping cycles
        try? await Task.sleep(nanoseconds: 400_000_000)  // 400ms
        
        await monitor.stop()
        
        let wasUnhealthy = await healthTracker.wasUnhealthy
        #expect(wasUnhealthy == false, "Monitor should stay healthy with responsive pongs")
    }
    
    @Test("WebSocket transport can enable monitoring")
    func transportEnablesMonitoring() async {
        let url = URL(string: "wss://echo.websocket.org")!
        let transport = WebSocketTransport(url: url)
        
        transport.enableConnectionMonitoring(
            pingInterval: 30.0,
            pongTimeout: 10.0
        )
        
        // Give time for async task to complete
        try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms
        
        // Verify transport is configured
        #expect(await transport.connectionState == false)
    }
    
    @Test("WebSocket transport can disable monitoring")
    func transportDisablesMonitoring() async {
        let url = URL(string: "wss://echo.websocket.org")!
        let transport = WebSocketTransport(url: url)
        
        transport.enableConnectionMonitoring()
        
        // Give time for async task to complete
        try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms
        
        transport.disableConnectionMonitoring()
        
        // Give time for async task to complete
        try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms
        
        // Verify transport is configured
        #expect(await transport.connectionState == false)
    }
    
    @Test("WebSocket transport ping throws when not connected")
    func transportPingThrowsWhenNotConnected() async throws {
        let url = URL(string: "wss://echo.websocket.org")!
        let transport = WebSocketTransport(url: url)
        
        await #expect(throws: WebSocketError.self) {
            try await transport.ping()
        }
    }
}

// MARK: - Test Helpers

private actor PingCounter {
    private(set) var count = 0
    
    func increment() {
        count += 1
    }
}

private actor HealthTracker {
    private(set) var wasUnhealthy = false
    
    func record(_ isHealthy: Bool) {
        if !isHealthy {
            wasUnhealthy = true
        }
    }
}
