# SwiftNetwork

A modern, Swift-native networking layer designed for simplicity, extensibility, and type safety. SwiftNetwork provides a clean, composable API for HTTP requests, streaming, WebSockets, authentication, caching, and more.

[![Swift Version](https://img.shields.io/badge/Swift-6.1+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2016+%20|%20macOS%2013+-blue.svg)](https://swift.org)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Documentation](https://img.shields.io/badge/Documentation-Available-brightgreen.svg)](https://erikote04.github.io/Swift-Network-Layer/documentation/swiftnetwork/)

## Features

- **Modern Swift Concurrency**: Built with async/await and actors for safe concurrent operations
- **Interceptor Chain**: Middleware system for request/response processing
- **Authentication**: Token-based auth with automatic refresh flows
- **Caching**: In-memory, disk, and hybrid caching options
- **Automatic Retries**: Configurable retry logic for transient failures
- **Streaming**: Stream large responses incrementally
- **Progress Reporting**: Upload and download progress callbacks
- **WebSockets**: Auth-aware WebSocket support with monitoring
- **Metrics**: Built-in metrics pipeline and collectors
- **Request Builder**: Fluent API for complex requests
- **Testable by Design**: Protocol-based composition for easy mocking
- **Swift Package Manager**: Easy integration with SPM

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
  - [NetworkClient](#networkclient)
  - [Request & Response](#request--response)
  - [Call](#call)
- [Usage Examples](#usage-examples)
  - [Basic GET Request](#basic-get-request)
  - [POST with JSON Body](#post-with-json-body)
  - [Using Request Builder](#using-request-builder)
  - [Decoding Responses](#decoding-responses)
  - [Streaming](#streaming)
  - [Progress](#progress)
  - [WebSockets](#websockets)
- [Advanced Features](#advanced-features)
  - [Interceptors](#interceptors)
  - [Authentication](#authentication)
  - [Response Caching](#response-caching)
  - [Retry Logic](#retry-logic)
  - [Logging](#logging)
  - [Metrics](#metrics)
- [Error Handling](#error-handling)
- [Documentation](#documentation)
- [Requirements](#requirements)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)

## Installation

### Swift Package Manager

Add SwiftNetwork to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Erikote04/Swift-Network-Layer.git")
]
```

Or add it through Xcode:

1. File > Add Package Dependencies...
2. Enter the repository URL: `https://github.com/Erikote04/Swift-Network-Layer.git`
3. Select `main` as target branch

## Quick Start

```swift
import SwiftNetwork

let client = NetworkClient(
    configuration: .init(baseURL: URL(string: "https://api.example.com")!)
)

let request = Request(
    method: .get,
    url: URL(string: "/users/123")!
)

do {
    let response = try await client.newCall(request).execute()
    print("Status: \(response.statusCode)")

    if let data = response.body {
        print("Received \(data.count) bytes")
    }
} catch {
    print("Request failed: \(error)")
}
```

## Core Concepts

### NetworkClient

`NetworkClient` is the main entry point for requests. It manages configuration, interceptors, and transports.

```swift
let client = NetworkClient()

let config = NetworkClientConfiguration(
    baseURL: URL(string: "https://api.example.com")!,
    defaultHeaders: [
        "Content-Type": "application/json",
        "Accept": "application/json"
    ],
    timeout: 30.0,
    interceptors: [
        LoggingInterceptor(level: .body),
        RetryInterceptor(maxRetries: 3)
    ]
)

let configuredClient = NetworkClient(configuration: config)
```

### Request & Response

**Request** is immutable and uses `RequestBody` for type-safe body encoding:

```swift
let request = Request(
    method: .post,
    url: URL(string: "https://api.example.com/users")!,
    headers: ["Authorization": "Bearer token"],
    body: .json(["name": "Alex"], encoder: JSONEncoder()),
    timeout: 15.0,
    cachePolicy: .ignoreCache
)
```

**Response** contains the result of a request:

```swift
struct Response {
    let request: Request
    let statusCode: Int
    let headers: HTTPHeaders
    let body: Data?

    var isSuccessful: Bool
}
```

### Call

A `Call` represents an executable request with cancellation support:

```swift
let call = client.newCall(request)

let response = try await call.execute()

await call.cancel()

if await call.isCancelled() {
    print("Call was cancelled")
}
```

## Usage Examples

### Basic GET Request

```swift
let request = Request(
    method: .get,
    url: URL(string: "https://api.example.com/users")!
)

let response = try await client.newCall(request).execute()
if response.isSuccessful {
    print("Success!")
}
```

### POST with JSON Body

```swift
struct User: Codable {
    let name: String
    let email: String
}

let user = User(name: "John Doe", email: "john@example.com")

let request = Request(
    method: .post,
    url: URL(string: "https://api.example.com/users")!,
    headers: ["Content-Type": "application/json"],
    body: .json(user)
)

let response = try await client.newCall(request).execute()
```

### Using Request Builder

```swift
var builder = RequestBuilder(
    method: .post,
    url: URL(string: "https://api.example.com/users")!
)

builder
    .header("Content-Type", "application/json")
    .header("Authorization", "Bearer \(token)")
    .body(.json(["name": "Alex"]))
    .timeout(20.0)
    .cachePolicy(.ignoreCache)

let request = builder.build()
let response = try await client.newCall(request).execute()
```

### Decoding Responses

```swift
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

let request = Request(
    method: .get,
    url: URL(string: "https://api.example.com/users/123")!
)

let user: User = try await client.newCall(request).execute()

let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
let customUser: User = try await client.newCall(request).execute(decoder: decoder)
```

### Streaming

```swift
let request = Request(
    method: .get,
    url: URL(string: "https://api.example.com/large-file")!
)

let call = client.newCall(request)
if let streamingCall = call as? StreamingCall {
    for try await chunk in streamingCall.stream() {
        print("Received \(chunk.count) bytes")
    }
}
```

### Progress

```swift
let request = Request(
    method: .post,
    url: URL(string: "https://api.example.com/upload")!,
    body: .data(Data(repeating: 0xFF, count: 1024 * 64))
)

let call = client.newCall(request)
if let progressCall = call as? ProgressCall {
    _ = try await progressCall.execute { progress in
        print("Progress: \(progress.fractionCompleted)")
    }
}
```

### WebSockets

```swift
let request = Request(
    method: .get,
    url: URL(string: "wss://example.com/socket")!
)

let call = client.newWebSocketCall(request)
try await call.connect()
try await call.send(text: "hello")
```

## Advanced Features

### Interceptors

```swift
struct CustomHeaderInterceptor: Interceptor {
    let headerValue: String

    func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        var modifiedRequest = chain.request
        var headers = modifiedRequest.headers
        headers["X-Custom-Header"] = headerValue

        let newRequest = Request(
            method: modifiedRequest.method,
            url: modifiedRequest.url,
            headers: headers,
            body: modifiedRequest.body,
            timeout: modifiedRequest.timeout
        )

        return try await chain.proceed(newRequest)
    }
}
```

### Authentication

```swift
struct MyAuthenticator: Authenticator {
    let tokenStore: TokenStore

    func authenticate(request: Request, response: Response) async throws -> Request? {
        guard response.statusCode == 401 else { return nil }

        let newToken = try await refreshToken()
        await tokenStore.store(newToken)

        var headers = request.headers
        headers["Authorization"] = "Bearer \(newToken)"

        return Request(
            method: request.method,
            url: request.url,
            headers: headers,
            body: request.body,
            timeout: request.timeout
        )
    }

    private func refreshToken() async throws -> String {
        return "new-access-token"
    }
}

let tokenStore = InMemoryTokenStore()
let authenticator = MyAuthenticator(tokenStore: tokenStore)

let config = NetworkClientConfiguration(
    interceptors: [
        AuthInterceptor(
            tokenStore: tokenStore,
            authenticator: authenticator
        )
    ]
)
```

### Response Caching

```swift
let cache = ResponseCache(ttl: 300)
let cacheInterceptor = CacheInterceptor(cache: cache)

let config = NetworkClientConfiguration(
    interceptors: [cacheInterceptor]
)

let request = Request(
    method: .get,
    url: URL(string: "/api/data")!,
    cachePolicy: .useCache
)
```

### Retry Logic

```swift
let retryInterceptor = RetryInterceptor(
    maxRetries: 3,
    delay: 0.5
)
```

### Logging

```swift
let basicLogger = LoggingInterceptor(level: .basic)
let headersLogger = LoggingInterceptor(level: .headers)
let fullLogger = LoggingInterceptor(level: .body)
```

### Metrics

```swift
let metrics = AggregateMetrics()
let config = NetworkClientConfiguration(metricsCollectors: [metrics])
```

## Error Handling

```swift
do {
    let user: User = try await client.newCall(request).execute()
    print("Success: \(user.name)")
} catch NetworkError.cancelled {
    print("Request was cancelled")
} catch NetworkError.noData {
    print("No data received")
} catch NetworkError.decodingError(let error) {
    print("Failed to decode response: \(error)")
} catch NetworkError.httpError(let statusCode, let body) {
    print("HTTP error \(statusCode)")
    if let data = body, let message = String(data: data, encoding: .utf8) {
        print("Error message: \(message)")
    }
} catch NetworkError.transportError(let error) {
    print("Network error: \(error)")
} catch {
    print("Unknown error: \(error)")
}
```

## Documentation

Explore the **[Documentation](https://erikote04.github.io/Swift-Network-Layer/documentation/swiftnetwork/)**. You can also launch the demo app from the Sample App folder and review the Sample App README for a walkthrough.

## Requirements

- **Swift**: 6.1 or later
- **iOS**: 16.0 or later
- **macOS**: 13.0 or later

## Architecture

SwiftNetwork follows a layered architecture:

```
┌─────────────────────────────────────┐
│          NetworkClient              │
│   (Configuration & Orchestration)   │
└─────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│         InterceptorChain            │
│   (Middleware & Request Pipeline)   │
└─────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│            Transport                │
│   (URLSession / Network Layer)      │
└─────────────────────────────────────┘
```

## Contributing

Contributions are welcome. Please feel free to submit a Pull Request. For major changes, open an issue first so we can discuss the approach.

## License

See `LICENSE` for details.

---

**Made with ❤️ by [Erik Sebastian de Erice](https://github.com/Erikote04)**
