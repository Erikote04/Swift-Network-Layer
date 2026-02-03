# Performance

Tune throughput and resource usage.

## Overview

Use ``RequestPriority`` to influence scheduling and ``RequestDeduplicator`` to collapse identical in-flight requests.

## Request priority

```swift
let request = Request(
    method: .get,
    url: URL(string: "/feed")!,
    priority: .high
)
```

## Deduplication

```swift
let config = NetworkClientConfiguration(enableDeduplication: true)
let client = NetworkClient(configuration: config)
```
