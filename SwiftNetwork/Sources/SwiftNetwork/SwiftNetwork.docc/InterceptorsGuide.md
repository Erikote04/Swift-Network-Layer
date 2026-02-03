# Interceptors

Compose cross-cutting behavior with interceptors.

## Overview

Interceptors implement ``Interceptor`` and can modify requests, short-circuit responses, or retry failures.

## Add interceptors

```swift
let config = NetworkClientConfiguration(
    interceptors: [
        DefaultHeadersInterceptor(headers: ["Accept": "application/json"]),
        LoggingInterceptor(),
        RetryInterceptor()
    ]
)
```

## Implement a custom interceptor

```swift
struct TraceInterceptor: Interceptor {
    func intercept(_ chain: InterceptorChainProtocol) async throws -> Response {
        var headers = chain.request.headers
        headers["X-Trace-Id"] = UUID().uuidString
        let request = Request(
            method: chain.request.method,
            url: chain.request.url,
            headers: headers,
            body: chain.request.body,
            timeout: chain.request.timeout,
            cachePolicy: chain.request.cachePolicy,
            priority: chain.request.priority
        )
        return try await chain.proceed(request)
    }
}
```
