# ``SwiftNetwork``

SwiftNetwork is a modern, interceptor-driven networking library for Swift, inspired by OkHttp and built on top of `URLSession`, Swift Concurrency, and structured async/await APIs. It provides a clean and extensible networking layer that allows applications to focus on business logic while delegating networking concerns—such as authentication, retries, caching, logging, and timeouts—to composable interceptors.

## Overview

SwiftNetwork is designed around a simple idea:

**Networking should be declarative, predictable, and extensible.**

Instead of scattering networking logic across the application, SwiftNetwork centralizes request execution and behavior in a configurable interceptor chain.

At its core, SwiftNetwork consists of:

- A high-level ``NetworkClient`` API
- An immutable ``Request`` / ``Response`` model
- A `Call` abstraction for request execution
- A composable interceptor pipeline
- A pluggable transport layer

---

## Architecture

A request in SwiftNetwork flows through the following layers:

1. **NetworkClient**  
   Entry point for creating and executing requests.

2. **Call**  
   Represents a single executable network operation.

3. **Interceptor Chain**  
   A pipeline of interceptors that can inspect, modify, retry, or short-circuit requests.

4. **Transport**  
   The final execution layer responsible for performing the network request.


Each interceptor decides whether to:

- Modify the request
- Proceed to the next interceptor
- Retry the request
- Return a cached response
- Fail with an error

---

## Interceptors

Interceptors are the core building blocks of SwiftNetwork.

They allow cross-cutting concerns to be expressed as isolated, reusable units that can be composed in different orders depending on application needs.

Built-in interceptors include:

- ``AuthInterceptor`` — Handles authentication and token refresh
- ``CacheInterceptor`` — Provides response caching
- ``RetryInterceptor`` — Retries failed requests
- ``TimeoutInterceptor`` — Applies request timeouts
- ``LoggingInterceptor`` — Logs requests and responses
- ``DefaultHeadersInterceptor`` — Injects dynamic default headers

Interceptors are executed in the order they are provided to the client.

---

## Authentication and Concurrency

SwiftNetwork provides a concurrency-safe authentication system.

When multiple requests fail due to an expired token:

- Only **one** token refresh is performed
- Other requests wait for the refresh to complete
- All requests resume using the updated token

This behavior is coordinated by `AuthRefreshCoordinator` and requires no manual synchronization from the application.

---

## Error Handling

All failures in SwiftNetwork are represented by ``NetworkError``.

Errors are surfaced consistently across:

- Transport failures
- HTTP errors
- Decoding issues
- Cancellation

This allows applications to handle errors at a single integration point.

---

## Getting Started

The recommended entry point is ``NetworkClient``.

```swift
let client = NetworkClient(
    configuration: NetworkClientConfiguration(
        baseURL: URL(string: "https://api.example.com"),
        interceptors: [
            AuthInterceptor(
                tokenStore: tokenStore,
                authenticator: authenticator
            ),
            RetryInterceptor(),
            LoggingInterceptor()
        ]
    )
)

let user: User = try await client.get("/user")
```

---

## Topics

### Client

* ``NetworkClient``
* ``NetworkClientConfiguration``
* ``NetworkClientProtocol``

### Requests and Responses

* ``Request``
* ``RequestBuilder``
* ``RequestBody``
* ``Response``
* ``HTTPMethod``
* ``HTTPHeaders``

### Interceptors

* ``Interceptor``
* ``InterceptorChainProtocol``
* ``AuthInterceptor``
* ``CacheInterceptor``
* ``RetryInterceptor``
* ``TimeoutInterceptor``
* ``LoggingInterceptor``
* ``DefaultHeadersInterceptor``

### Authentication

* ``Authenticator``
* ``TokenStore``
* ``InMemoryTokenStore``

### Cache

* ``ResponseCache``
* ``CachePolicy``

### Errors

* ``NetworkError``
