# Requests and Responses

Model requests and read structured responses.

## Overview

``Request`` values are immutable and define method, URL, headers, body, cache policy, and priority. ``Response`` holds status, headers, and body.

## Build a request

```swift
let request = Request(
    method: .post,
    url: URL(string: "/login")!,
    headers: ["Accept": "application/json"],
    body: .json(credentials)
)
```

## Execute and decode

```swift
let response = try await client.newCall(request).execute()
let user: User = try await client.newCall(request).execute()
```
