# Token Stores

Persist and retrieve authentication tokens.

## Overview

Use ``TokenStore`` to abstract token persistence. SwiftNetwork provides in-memory and keychain implementations.

## In-memory store

```swift
let tokenStore = InMemoryTokenStore()
await tokenStore.updateToken("token")
```

## Keychain store

```swift
let tokenStore = KeychainTokenStore(service: "com.example.swiftNetwork")
await tokenStore.updateToken("token")
```
