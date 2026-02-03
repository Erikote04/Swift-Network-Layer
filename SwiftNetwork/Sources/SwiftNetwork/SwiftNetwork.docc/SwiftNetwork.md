# ``SwiftNetwork``

Modern networking with composable interceptors and Swift Concurrency.

## Overview

SwiftNetwork centralizes request execution in a configurable interceptor chain so apps can focus on business logic instead of network plumbing.

At its core, SwiftNetwork consists of:

- A high-level ``NetworkClient`` API
- An immutable ``Request`` / ``Response`` model
- A ``Call`` abstraction for request execution
- A composable interceptor pipeline
- A pluggable transport layer

---

## Architecture

A request in SwiftNetwork flows through the following layers:

1. **NetworkClient**  
   Entry point for creating and executing requests.

2. **Call**  
   Represents a single executable network operation.

3. **Interceptor Chain**  
   A pipeline of interceptors that can inspect, modify, retry, or short-circuit requests.

4. **Transport**  
   The final execution layer responsible for performing the network request.


Each interceptor decides whether to:

- Modify the request
- Proceed to the next interceptor
- Retry the request
- Return a cached response
- Fail with an error

## Topics

### Integration Guides

* <doc:GettingStartedGuide>
* <doc:ConfigurationGuide>
* <doc:RequestsGuide>
* <doc:CallsGuide>
* <doc:InterceptorsGuide>
* <doc:AuthenticationGuide>
* <doc:TokenStoresGuide>
* <doc:AuthProvidersAppleGuide>
* <doc:AuthProvidersGoogleGuide>
* <doc:CachingGuide>
* <doc:RetriesGuide>
* <doc:LoggingGuide>
* <doc:TimeoutsGuide>
* <doc:MetricsGuide>
* <doc:PerformanceGuide>
* <doc:ProgressAndStreamingGuide>
* <doc:WebSocketsGuide>
* <doc:SecurityAndPinningGuide>
* <doc:DeduplicationGuide>

### Client

* ``NetworkClient``
* ``NetworkClientConfiguration``
* ``NetworkClientProtocol``

### Requests and Responses

* ``Request``
* ``RequestBuilder``
* ``RequestBody``
* ``MultipartFormData``
* ``Response``
* ``HTTPMethod``
* ``HTTPHeaders``

### Calls

* ``Call``
* ``ProgressCall``
* ``SwiftNetwork/Progress-struct``
* ``StreamingCall``
* ``StreamingResponse``
* ``RequestPriority``

### Interceptors

* ``Interceptor``
* ``InterceptorChainProtocol``
* ``RequestInterceptor``
* ``ResponseInterceptor``
* ``PrioritizedInterceptor``
* ``ConditionalInterceptor``
* ``AuthInterceptor``
* ``CacheInterceptor``
* ``RetryInterceptor``
* ``TimeoutInterceptor``
* ``LoggingInterceptor``
* ``DefaultHeadersInterceptor``
* ``MetricsInterceptor``

### Authentication

* ``AuthManager``
* ``AuthRefreshCoordinator``
* ``Authenticator``
* ``AuthProvider``
* ``AuthProviderType``
* ``AuthCredentials``
* ``AuthError``
* ``TokenStore``
* ``InMemoryTokenStore``
* ``KeychainTokenStore``
* ``AppleAuthProvider``
* ``GoogleAuthProvider``

### Cache

* ``ResponseCache``
* ``CacheStorage``
* ``CacheEntry``
* ``CachePolicy``
* ``CacheStorageError``
* ``DiskCacheStorage``
* ``HybridCacheStorage``

### Metrics

* ``NetworkMetrics``
* ``AggregateMetrics``
* ``AggregateMetrics/Snapshot``
* ``CompositeMetrics``
* ``ConsoleMetrics``
* ``FilteredMetrics``
* ``FilteredMetrics/MetricEvent``
* ``RequestMetricEvent``
* ``ErrorMetricEvent``
* ``RetryMetricEvent``
* ``CacheMetricEvent``
* ``CacheMetricEvent/CacheResult``

### Performance

* ``RequestDeduplicator``
* ``RequestPriority``

### Security

* ``CertificatePinner``
* ``CertificatePinner/Pin``
* ``CertificatePinner/Policy``

### WebSockets

* ``WebSocketCall``
* ``BaseWebSocketCall``
* ``WebSocketTransport``
* ``WebSocketConnectionMonitor``
* ``WebSocketMessage``
* ``WebSocketError``

### Errors

* ``NetworkError``
