# Deduplication

Share identical in-flight requests.

## Overview

Enable request deduplication to collapse concurrent identical requests into a single network call.

## Enable deduplication

```swift
let config = NetworkClientConfiguration(enableDeduplication: true)
let client = NetworkClient(configuration: config)
```
