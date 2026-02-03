# Google Sign-In

Integrate Google Sign-In using ``GoogleAuthProvider``.

## Overview

``GoogleAuthProvider`` exchanges Google OAuth credentials and returns ``AuthCredentials``.

## Authenticate

```swift
let provider = GoogleAuthProvider(
    clientID: "client-id",
    clientSecret: "client-secret",
    redirectURI: "com.example.app:/oauth2redirect"
)

let credentials = try await provider.login()
```
