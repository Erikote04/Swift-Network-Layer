# Calls

Execute, cancel, and observe request lifecycle.

## Overview

A ``Call`` represents a single executable request. Calls are Sendable and safe to use across concurrency domains.

## Execute a call

```swift
let call = client.newCall(request)
let response = try await call.execute()
```

## Cancel a call

```swift
await call.cancel()
```

## Check cancellation

```swift
let wasCancelled = await call.isCancelled()
```
