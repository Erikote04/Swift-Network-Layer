# Timeouts

Apply consistent request timeouts.

## Overview

``TimeoutInterceptor`` enforces timeouts across requests, with per-request overrides.

## Configure a default timeout

```swift
let timeout = TimeoutInterceptor(defaultTimeout: 20)
let config = NetworkClientConfiguration(interceptors: [timeout])
```

## Override per request

```swift
let request = Request(
    method: .get,
    url: URL(string: "/slow")!,
    timeout: 60
)
```
