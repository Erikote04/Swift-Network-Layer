# WebSockets

Connect and monitor real-time streams.

## Overview

``WebSocketCall`` establishes a WebSocket connection and returns ``WebSocketTransport`` for bidirectional messaging.

## Create a WebSocket call

```swift
let request = Request(method: .get, url: URL(string: "/ws")!)
let call = client.newWebSocketCall(request)
let transport = try await call.connect()
```

## Enable monitoring

```swift
transport.enableConnectionMonitoring(
    pingInterval: 30,
    pongTimeout: 10
)
```
