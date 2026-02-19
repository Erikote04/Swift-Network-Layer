//
//  RetryMetricsCollector.swift
//  SwiftNetworkSampleApp
//
//  Created by SwiftNetwork Contributors on 3/2/26.
//

import Foundation
import SwiftNetwork

actor RetryMetricsCollector: NetworkMetrics {
    private(set) var retries: Int = 0

    func recordRequest(_ event: RequestMetricEvent) async { }
    func recordError(_ event: ErrorMetricEvent) async { }
    func recordCacheEvent(_ event: CacheMetricEvent) async { }

    @available(*, deprecated, renamed: "recordCacheEvent(_:)")
    func recordCacheHit(_ event: CacheMetricEvent) async {
        await recordCacheEvent(event)
    }

    func recordRetry(_ event: RetryMetricEvent) async {
        retries += 1
    }

    func reset() async {
        retries = 0
    }

    func count() async -> Int {
        retries
    }
}
