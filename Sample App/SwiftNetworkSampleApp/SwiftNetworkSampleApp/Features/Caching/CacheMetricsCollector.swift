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

    func recordCacheHit(_ event: CacheMetricEvent) async {
        lastCacheResult = event.result
    }

    func reset() async {
        lastCacheResult = nil
    }

    func latestResult() async -> CacheMetricEvent.CacheResult? {
        lastCacheResult
    }
}
