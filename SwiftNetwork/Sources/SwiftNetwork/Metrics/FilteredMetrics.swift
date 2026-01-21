//
//  FilteredMetrics.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 21/1/26.
//

import Foundation

/// A metrics collector that filters events before forwarding them.
///
/// `FilteredMetrics` wraps another collector and only forwards events
/// that match specified criteria. This is useful for:
/// - Recording metrics only for specific endpoints
/// - Filtering by HTTP method
/// - Excluding certain status codes
/// - Focusing on production environments
///
/// ## Usage
///
/// ```swift
/// let console = ConsoleMetrics()
///
/// // Only log errors
/// let errorsOnly = FilteredMetrics(collector: console) { event in
///     if case .error = event {
///         return true
///     }
///     return false
/// }
///
/// // Only log API calls
/// let apiOnly = FilteredMetrics(collector: console) { event in
///     event.url.absoluteString.contains("/api/")
/// }
/// ```
public actor FilteredMetrics: NetworkMetrics {
    
    /// A filter function that determines whether an event should be recorded.
    public typealias Filter = @Sendable (MetricEvent) -> Bool
    
    /// Represents any metric event type.
    public enum MetricEvent: Sendable {
        case request(RequestMetricEvent)
        case error(ErrorMetricEvent)
        case retry(RetryMetricEvent)
        case cache(CacheMetricEvent)
        
        /// The URL associated with the event.
        public var url: URL {
            switch self {
            case .request(let event): return event.url
            case .error(let event): return event.url
            case .retry(let event): return event.url
            case .cache(let event): return event.url
            }
        }
        
        /// The HTTP method associated with the event.
        public var method: HTTPMethod {
            switch self {
            case .request(let event): return event.method
            case .error(let event): return event.method
            case .retry(let event): return event.method
            case .cache(let event): return event.method
            }
        }
    }
    
    private let collector: NetworkMetrics
    private let filter: Filter
    
    /// Creates a new filtered metrics collector.
    ///
    /// - Parameters:
    ///   - collector: The underlying collector to forward filtered events to.
    ///   - filter: A function that returns `true` for events that should be recorded.
    public init(
        collector: NetworkMetrics,
        filter: @escaping Filter
    ) {
        self.collector = collector
        self.filter = filter
    }
    
    public func recordRequest(_ event: RequestMetricEvent) async {
        if filter(.request(event)) {
            await collector.recordRequest(event)
        }
    }
    
    public func recordError(_ event: ErrorMetricEvent) async {
        if filter(.error(event)) {
            await collector.recordError(event)
        }
    }
    
    public func recordRetry(_ event: RetryMetricEvent) async {
        if filter(.retry(event)) {
            await collector.recordRetry(event)
        }
    }
    
    public func recordCacheHit(_ event: CacheMetricEvent) async {
        if filter(.cache(event)) {
            await collector.recordCacheHit(event)
        }
    }
}

// MARK: - Convenience Filters

extension FilteredMetrics {
    
    /// Creates a metrics collector that only records events for specific HTTP methods.
    ///
    /// - Parameters:
    ///   - collector: The underlying collector.
    ///   - methods: The HTTP methods to include.
    /// - Returns: A filtered metrics collector.
    public static func methods(
        _ methods: Set<HTTPMethod>,
        collector: NetworkMetrics
    ) -> FilteredMetrics {
        FilteredMetrics(collector: collector) { event in
            methods.contains(event.method)
        }
    }
    
    /// Creates a metrics collector that only records events for URLs matching a pattern.
    ///
    /// - Parameters:
    ///   - collector: The underlying collector.
    ///   - pattern: A regex pattern to match against URLs.
    /// - Returns: A filtered metrics collector.
    public static func urlPattern(
        _ pattern: String,
        collector: NetworkMetrics
    ) -> FilteredMetrics {
        FilteredMetrics(collector: collector) { event in
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                return false
            }
            let urlString = event.url.absoluteString
            let range = NSRange(urlString.startIndex..., in: urlString)
            return regex.firstMatch(in: urlString, range: range) != nil
        }
    }
    
    /// Creates a metrics collector that only records events containing specific tags.
    ///
    /// - Parameters:
    ///   - collector: The underlying collector.
    ///   - requiredTags: Tags that must be present in the event.
    /// - Returns: A filtered metrics collector.
    public static func tags(
        _ requiredTags: [String: String],
        collector: NetworkMetrics
    ) -> FilteredMetrics {
        FilteredMetrics(collector: collector) { event in
            let eventTags: [String: String]
            
            switch event {
            case .request(let e): eventTags = e.tags
            case .error(let e): eventTags = e.tags
            case .retry(let e): eventTags = e.tags
            case .cache(let e): eventTags = e.tags
            }
            
            for (key, value) in requiredTags {
                if eventTags[key] != value {
                    return false
                }
            }
            return true
        }
    }
    
    /// Creates a metrics collector that only records error events.
    ///
    /// - Parameter collector: The underlying collector.
    /// - Returns: A filtered metrics collector.
    public static func errorsOnly(
        collector: NetworkMetrics
    ) -> FilteredMetrics {
        FilteredMetrics(collector: collector) { event in
            if case .error = event {
                return true
            }
            return false
        }
    }
    
    /// Creates a metrics collector that only records successful requests.
    ///
    /// - Parameter collector: The underlying collector.
    /// - Returns: A filtered metrics collector.
    public static func successOnly(
        collector: NetworkMetrics
    ) -> FilteredMetrics {
        FilteredMetrics(collector: collector) { event in
            if case .request(let requestEvent) = event {
                return (200..<300).contains(requestEvent.statusCode)
            }
            return false
        }
    }
}
