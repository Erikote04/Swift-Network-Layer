# Configuration

Define global behavior for a ``NetworkClient``.

## Overview

``NetworkClientConfiguration`` controls base URL resolution, default headers, timeouts, interceptors, caching, and certificate pinning.

## Configure defaults

```swift
let config = NetworkClientConfiguration(
    baseURL: URL(string: "https://api.example.com"),
    defaultHeaders: ["Accept": "application/json"],
    timeout: 30,
    interceptors: [LoggingInterceptor()]
)
```

## Use a custom URLSession

```swift
let session = URLSession(configuration: .ephemeral)
let client = NetworkClient(configuration: config, session: session)
```
