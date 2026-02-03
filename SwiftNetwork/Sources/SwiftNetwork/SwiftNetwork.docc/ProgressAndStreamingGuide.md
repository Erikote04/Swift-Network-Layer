# Progress and Streaming

Report progress and stream large responses.

## Overview

Use ``ProgressCall`` for upload and download progress, and ``StreamingCall`` for incremental response processing.

## Progress

```swift
let call = client.newCall(request)
if let progressCall = call as? ProgressCall {
    _ = try await progressCall.execute { progress in
        print(progress.fractionCompleted)
    }
}
```

## Streaming

```swift
let call = client.newCall(request)
if let streamingCall = call as? StreamingCall {
    for try await chunk in streamingCall.stream() {
        handle(chunk)
    }
}
```
