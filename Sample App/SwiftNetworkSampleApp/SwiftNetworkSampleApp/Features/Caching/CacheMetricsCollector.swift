//
//  CacheMetricsCollector.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

actor CacheMetricsCollector: NetworkMetrics {
    private var lastCacheResult: CacheMetricEvent.CacheResult?

    func recordRequest(_ event: RequestMetricEvent) async { }
    func recordError(_ event: ErrorMetricEvent) async { }
    func recordRetry(_ event: RetryMetricEvent) async { }

    func recordCacheEvent(_ event: CacheMetricEvent) async {
        lastCacheResult = event.result
    }

    @available(*, deprecated, renamed: "recordCacheEvent(_:)")
    func recordCacheHit(_ event: CacheMetricEvent) async {
        await recordCacheEvent(event)
    }

    func reset() async {
        lastCacheResult = nil
    }

    func latestResult() async -> CacheMetricEvent.CacheResult? {
        lastCacheResult
    }
}
