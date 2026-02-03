# Getting Started

Build a client and execute your first request.

## Overview

SwiftNetwork centers around ``NetworkClient`` and immutable ``Request`` values. Most apps only need a single client configured at startup.

## Configure a client

```swift
let client = NetworkClient(
    configuration: NetworkClientConfiguration(
        baseURL: URL(string: "https://api.example.com"),
        interceptors: [
            LoggingInterceptor(),
            RetryInterceptor()
        ]
    )
)
```

## Execute a request

```swift
let user: User = try await client.get("/user")
```

## Next steps

- Add authentication with <doc:AuthenticationGuide>.
- Enable caching with <doc:CachingGuide>.
- Use streaming for large downloads with <doc:ProgressAndStreamingGuide>.
