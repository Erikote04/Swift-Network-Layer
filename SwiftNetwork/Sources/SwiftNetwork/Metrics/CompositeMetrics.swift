//
//  CompositeMetrics.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 21/1/26.
//

import Foundation

/// A metrics collector that forwards events to multiple collectors.
///
/// `CompositeMetrics` enables combining different metrics implementations,
/// allowing simultaneous logging, aggregation, and custom processing.
///
/// ## Usage
///
/// ```swift
/// let console = ConsoleMetrics()
/// let aggregate = AggregateMetrics()
/// let composite = CompositeMetrics(collectors: [console, aggregate])
///
/// let interceptor = MetricsInterceptor(metrics: composite)
///
/// // Later, access aggregated statistics
/// let stats = await aggregate.snapshot()
/// ```
///
/// ## Thread Safety
///
/// This actor safely coordinates multiple collectors concurrently,
/// ensuring all collectors receive events in order.
public actor CompositeMetrics: NetworkMetrics {
    
    private let collectors: [NetworkMetrics]
    
    /// Creates a new composite metrics collector.
    ///
    /// - Parameter collectors: The metrics collectors to forward events to.
    public init(collectors: [NetworkMetrics]) {
        self.collectors = collectors
    }
    
    public func recordRequest(_ event: RequestMetricEvent) async {
        await withTaskGroup(of: Void.self) { group in
            for collector in collectors {
                group.addTask {
                    await collector.recordRequest(event)
                }
            }
        }
    }
    
    public func recordError(_ event: ErrorMetricEvent) async {
        await withTaskGroup(of: Void.self) { group in
            for collector in collectors {
                group.addTask {
                    await collector.recordError(event)
                }
            }
        }
    }
    
    public func recordRetry(_ event: RetryMetricEvent) async {
        await withTaskGroup(of: Void.self) { group in
            for collector in collectors {
                group.addTask {
                    await collector.recordRetry(event)
                }
            }
        }
    }
    
    public func recordCacheHit(_ event: CacheMetricEvent) async {
        await withTaskGroup(of: Void.self) { group in
            for collector in collectors {
                group.addTask {
                    await collector.recordCacheHit(event)
                }
            }
        }
    }
}
