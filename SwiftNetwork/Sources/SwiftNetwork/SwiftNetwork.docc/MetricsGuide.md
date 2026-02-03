# Metrics

Track request, error, retry, and cache events.

## Overview

Use ``AggregateMetrics`` and related types to record and inspect client performance.

## Record metrics

```swift
let metrics = AggregateMetrics()
await metrics.recordRequest(RequestMetricEvent(...))
let snapshot = await metrics.snapshot()
```
