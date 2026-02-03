# Authentication

Integrate token storage and refresh flows.

## Overview

Use ``AuthInterceptor`` with a ``TokenStore`` or ``AuthManager`` to attach tokens and refresh them safely across concurrent requests.

## Token store

```swift
let tokenStore = InMemoryTokenStore()
let auth = AuthInterceptor(tokenStore: tokenStore)

let config = NetworkClientConfiguration(interceptors: [auth])
let client = NetworkClient(configuration: config)
```

## Auth manager

```swift
let manager = AuthManager(tokenStore: tokenStore)
await manager.setRefreshProvider { refreshToken in
    try await authService.refresh(refreshToken)
}

let auth = AuthInterceptor(authManager: manager)
```
