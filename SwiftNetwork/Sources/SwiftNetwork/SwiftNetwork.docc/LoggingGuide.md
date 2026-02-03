# Logging

Log requests and responses for diagnostics.

## Overview

``LoggingInterceptor`` prints request and response details, with optional body logging.

## Enable logging

```swift
let logging = LoggingInterceptor(logLevel: .headers)
let config = NetworkClientConfiguration(interceptors: [logging])
```
