# Sign in with Apple

Integrate Sign in with Apple using ``AppleAuthProvider``.

## Overview

``AppleAuthProvider`` implements Sign in with Apple, handling the authorization flow and credential exchange.

## Authenticate

```swift
let provider = AppleAuthProvider(scopes: [.fullName, .email])
let credentials = try await provider.login()
```

## Use with AuthManager

```swift
let tokenStore = InMemoryTokenStore()
let authManager = AuthManager(tokenStore: tokenStore)

let credentials = try await provider.login()
_ = try await authManager.login(provider: provider)
```
