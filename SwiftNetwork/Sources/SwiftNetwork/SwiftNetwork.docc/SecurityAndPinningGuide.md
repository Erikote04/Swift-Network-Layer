# Security and Pinning

Pin certificates or public keys.

## Overview

Use ``CertificatePinner`` to pin certificates or public keys and enforce trust.

## Configure pinning

```swift
let pinner = CertificatePinner(
    pins: [
        "api.example.com": [
            .publicKeyHash("sha256/BASE64")
        ]
    ]
)

let config = NetworkClientConfiguration(certificatePinner: pinner)
let client = NetworkClient(configuration: config)
```
