# Retries

Retry failed requests with backoff.

## Overview

``RetryInterceptor`` retries transient failures and records retry metrics when enabled.

## Enable retries

```swift
let retry = RetryInterceptor(
    maxAttempts: 3,
    baseDelay: 0.5
)

let config = NetworkClientConfiguration(interceptors: [retry])
```
