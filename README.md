# SwiftNetwork

A modern, Swift-native networking layer designed for simplicity, extensibility, and type safety. SwiftNetwork provides a clean, composable API for making HTTP requests with built-in support for interceptors, caching, authentication, and more.

[![Swift Version](https://img.shields.io/badge/Swift-6.1+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2016+%20|%20macOS%2013+-blue.svg)](https://swift.org)
[![SPM Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Documentation](https://img.shields.io/badge/Documentation-Available-brightgreen.svg)](https://erikote04.github.io/Swift-Network-Layer/documentation/swiftnetwork/)

## Features

- **🚀 Modern Swift Concurrency**: Built with async/await and actors for safe concurrent operations
- **🔌 Interceptor Chain**: Powerful middleware system for request/response processing
- **🔐 Authentication**: Built-in support for token-based authentication with automatic refresh
- **💾 Response Caching**: In-memory caching with configurable TTL
- **🔄 Automatic Retries**: Configurable retry logic for transient failures
- **📝 Request Logging**: Detailed logging with multiple verbosity levels
- **⏱️ Timeout Control**: Per-request and global timeout configuration
- **🎯 Type-Safe**: Strongly-typed responses with automatic JSON decoding
- **🧪 Testable**: Protocol-based design for easy mocking and testing
- **📦 Swift Package Manager**: Easy integration with SPM

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
  - [NetworkClient](#networkclient)
  - [Request & Response](#request--response)
  - [Call](#call)
  - [Interceptors](#interceptors)
- [Usage Examples](#usage-examples)
  - [Basic GET Request](#basic-get-request)
  - [POST with JSON Body](#post-with-json-body)
  - [Using Request Builder](#using-request-builder)
  - [Decoding Responses](#decoding-responses)
  - [Custom Headers](#custom-headers)
  - [Timeout Configuration](#timeout-configuration)
- [Advanced Features](#advanced-features)
  - [Interceptors](#interceptors-1)
  - [Authentication](#authentication)
  - [Response Caching](#response-caching)
  - [Retry Logic](#retry-logic)
  - [Logging](#logging)
- [Error Handling](#error-handling)
- [Documentation](#documentation)
- [Requirements](#requirements)
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

Here's a simple example to get you started:

```swift
import SwiftNetwork

// Create a network client
let client = NetworkClient(
    configuration: .init(baseURL: URL(string: "https://api.example.com")!)
)

// Create a request
let request = Request(
    method: .get,
    url: URL(string: "/users/123")!
)

// Execute the request
do {
    let response = try await client.newCall(request).execute()
    print("Status: \(response.statusCode)")
    
    if let data = response.body {
        // Process response data
        print("Received \(data.count) bytes")
    }
} catch {
    print("Request failed: \(error)")
}
```

## Core Concepts

### NetworkClient

`NetworkClient` is the main entry point for making network requests. It manages configuration, interceptors, and request execution.

```swift
// Basic client
let client = NetworkClient()

// Client with custom configuration
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

let client = NetworkClient(configuration: config)
```

### Request & Response

**Request** represents an immutable HTTP request with all necessary information:

```swift
let request = Request(
    method: .post,
    url: URL(string: "https://api.example.com/users")!,
    headers: ["Authorization": "Bearer token"],
    body: jsonData,
    timeout: 15.0,
    cachePolicy: .ignoreCache
)
```

**Response** contains the result of a completed request:

```swift
struct Response {
    let request: Request        // Original request
    let statusCode: Int         // HTTP status code
    let headers: HTTPHeaders    // Response headers
    let body: Data?            // Response body
    
    var isSuccessful: Bool     // true if status is 2xx
}
```

### Call

A `Call` represents an executable network request. It can be executed, cancelled, and queried for its state:

```swift
let call = client.newCall(request)

// Execute the call
let response = try await call.execute()

// Cancel the call
call.cancel()

// Check if cancelled
if call.isCancelled {
    print("Call was cancelled")
}
```

### Interceptors

Interceptors form a chain that can inspect, modify, retry, cache, or short-circuit network requests. They're executed in order before the request reaches the transport layer.

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
let jsonData = try JSONEncoder().encode(user)

let request = Request(
    method: .post,
    url: URL(string: "https://api.example.com/users")!,
    headers: ["Content-Type": "application/json"],
    body: jsonData
)

let response = try await client.newCall(request).execute()
```

### Using Request Builder

For more complex requests, use `RequestBuilder`:

```swift
var builder = RequestBuilder(
    method: .post,
    url: URL(string: "https://api.example.com/users")!
)

builder
    .header("Content-Type", "application/json")
    .header("Authorization", "Bearer \(token)")
    .body(jsonData)
    .timeout(20.0)
    .cachePolicy(.ignoreCache)

let request = builder.build()
let response = try await client.newCall(request).execute()
```

### Decoding Responses

SwiftNetwork provides convenient extensions for automatic JSON decoding:

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

// Automatically decode the response
let user: User = try await client.newCall(request).execute()
print("User name: \(user.name)")

// With custom decoder
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase

let user: User = try await client.newCall(request).execute(decoder: decoder)
```

### Custom Headers

```swift
// Per-request headers
let request = Request(
    method: .get,
    url: URL(string: "/api/data")!,
    headers: [
        "Authorization": "Bearer \(accessToken)",
        "X-Custom-Header": "custom-value"
    ]
)

// Global default headers
let config = NetworkClientConfiguration(
    defaultHeaders: [
        "User-Agent": "MyApp/1.0",
        "Accept": "application/json"
    ]
)
let client = NetworkClient(configuration: config)
```

### Timeout Configuration

```swift
// Global timeout
let config = NetworkClientConfiguration(timeout: 30.0)
let client = NetworkClient(configuration: config)

// Per-request timeout (overrides global)
let request = Request(
    method: .get,
    url: URL(string: "https://api.example.com/slow-endpoint")!,
    timeout: 60.0
)
```

## Advanced Features

### Interceptors

#### Creating Custom Interceptors

```swift
struct CustomHeaderInterceptor: Interceptor {
    let headerValue: String
    
    func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        var modifiedRequest = chain.request
        
        // Add custom header to all requests
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

// Use the interceptor
let config = NetworkClientConfiguration(
    interceptors: [CustomHeaderInterceptor(headerValue: "my-value")]
)
```

#### Built-in Interceptors

**LoggingInterceptor**: Logs request and response details

```swift
let loggingInterceptor = LoggingInterceptor(level: .body)
// Levels: .none, .basic, .headers, .body
```

**RetryInterceptor**: Automatically retries failed requests

```swift
let retryInterceptor = RetryInterceptor(
    maxRetries: 3,
    delay: 0.5
)
```

**CacheInterceptor**: Caches successful GET responses

```swift
let cache = ResponseCache(ttl: 300) // 5 minutes
let cacheInterceptor = CacheInterceptor(cache: cache)
```

**TimeoutInterceptor**: Enforces request timeouts

```swift
let timeoutInterceptor = TimeoutInterceptor(timeout: 30.0)
```

**DefaultHeadersInterceptor**: Adds default headers to all requests

```swift
let headersInterceptor = DefaultHeadersInterceptor(
    headers: ["User-Agent": "MyApp/1.0"]
)
```

### Authentication

SwiftNetwork provides a robust authentication system with automatic token refresh:

#### Implementing an Authenticator

```swift
struct MyAuthenticator: Authenticator {
    let tokenStore: TokenStore
    
    func authenticate(request: Request, response: Response) async throws -> Request? {
        // Only handle 401 Unauthorized
        guard response.statusCode == 401 else {
            return nil
        }
        
        // Attempt to refresh the token
        let newToken = try await refreshToken()
        
        // Store the new token
        await tokenStore.store(newToken)
        
        // Create a new request with the updated token
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
        // Implement your token refresh logic here
        // This might involve calling a refresh endpoint
        // ...
        return "new-access-token"
    }
}
```

#### Using the AuthInterceptor

```swift
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

let client = NetworkClient(configuration: config)
```

#### Token Storage

Implement `TokenStore` for custom token storage:

```swift
actor KeychainTokenStore: TokenStore {
    func retrieve() -> String? {
        // Retrieve from keychain
        return keychainService.get("access_token")
    }
    
    func store(_ token: String) {
        // Store in keychain
        keychainService.set("access_token", value: token)
    }
    
    func clear() {
        // Clear from keychain
        keychainService.delete("access_token")
    }
}
```

### Response Caching

```swift
// Create a cache with 5-minute TTL
let cache = ResponseCache(ttl: 300)
let cacheInterceptor = CacheInterceptor(cache: cache)

let config = NetworkClientConfiguration(
    interceptors: [cacheInterceptor]
)

// Control caching per-request
let request = Request(
    method: .get,
    url: URL(string: "/api/data")!,
    cachePolicy: .useCache  // or .ignoreCache
)
```

### Retry Logic

```swift
let retryInterceptor = RetryInterceptor(
    maxRetries: 3,      // Number of retry attempts
    delay: 0.5          // Delay between retries (seconds)
)

let config = NetworkClientConfiguration(
    interceptors: [retryInterceptor]
)
```

### Logging

```swift
// Basic logging (method, URL, status, duration)
let basicLogger = LoggingInterceptor(level: .basic)

// With headers
let headersLogger = LoggingInterceptor(level: .headers)

// With full body
let fullLogger = LoggingInterceptor(level: .body)

// Output examples:
// ➡️ GET https://api.example.com/users
// ⬅️ 200 (0.45s)

// With .body level:
// ➡️ POST https://api.example.com/users
// Headers:
//   Content-Type: application/json
// Body:
// {"name":"John","email":"john@example.com"}
// ⬅️ 201 (0.67s)
```

## Error Handling

SwiftNetwork defines a comprehensive `NetworkError` enum for all failure cases:

```swift
enum NetworkError: Error {
    case cancelled                      // Request was cancelled
    case invalidResponse                // Invalid HTTP response
    case transportError(Error)          // Underlying transport error
    case noData                         // No response body when expected
    case decodingError(Error)           // JSON decoding failed
    case httpError(statusCode: Int, body: Data?)  // Non-2xx status code
}
```

### Handling Errors

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

Explore the **[Documentation](https://erikote04.github.io/Swift-Network-Layer/documentation/swiftnetwork/)** to see more details

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

### Key Design Principles

1. **Immutability**: Request and Response objects are immutable for thread safety
2. **Protocol-Oriented**: Heavy use of protocols for flexibility and testability
3. **Concurrency-Safe**: Built with Swift's concurrency model (async/await, actors)
4. **Separation of Concerns**: Clear boundaries between layers
5. **Extensibility**: Easy to add custom interceptors and behaviors

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## Acknowledgments

SwiftNetwork was inspired by modern networking libraries like Retrofit, OkHttp, and Alamofire, adapted for Swift's concurrency model and type system.

---

**Made with ❤️ by [Erik Sebastian de Erice](https://github.com/Erikote04)**

For questions, issues, or feature requests, please visit the [GitHub repository](https://github.com/Erikote04/Swift-Network-Layer).
