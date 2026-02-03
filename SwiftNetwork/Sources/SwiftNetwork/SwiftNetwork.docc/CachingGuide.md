# Caching

Cache responses and control cache policy.

## Overview

Use ``CacheInterceptor`` and ``ResponseCache`` to cache responses and reduce network load.

## Enable caching

```swift
let cache = ResponseCache()
let cacheInterceptor = CacheInterceptor(cache: cache)

let config = NetworkClientConfiguration(interceptors: [cacheInterceptor])
```

## Control per-request policy

```swift
let request = Request(
    method: .get,
    url: URL(string: "/articles")!,
    cachePolicy: .useCache
)
```
