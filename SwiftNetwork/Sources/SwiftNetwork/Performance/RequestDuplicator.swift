//
//  RequestDeduplicator.swift
//  SwiftNetwork
//
//  Performance layer for request deduplication.
//

import Foundation

/// Manages deduplication of identical in-flight requests.
///
/// `RequestDeduplicator` ensures that multiple identical requests made
/// concurrently share a single network call, reducing bandwidth and
/// server load while improving response times.
public actor RequestDeduplicator {
    
    /// Active in-flight requests indexed by their deduplication key.
    private var inFlightRequests: [String: Task<Response, Error>] = [:]
    
    /// Creates a new request deduplicator.
    public init() {}
    
    /// Deduplicates a request by sharing the result of identical in-flight requests.
    ///
    /// If an identical request is already in progress, this method returns the
    /// shared result. Otherwise, it executes the provided closure and caches
    /// the task for subsequent identical requests.
    ///
    /// - Parameters:
    ///   - request: The request to deduplicate.
    ///   - execute: A closure that executes the request when no duplicate is found.
    /// - Returns: The response from either the shared or newly executed request.
    /// - Throws: Any error encountered during request execution.
    public func deduplicate(
        request: Request,
        execute: @escaping @Sendable () async throws -> Response
    ) async throws -> Response {
        let key = deduplicationKey(for: request)
        
        // Return existing in-flight request if available
        if let existingTask = inFlightRequests[key] {
            return try await existingTask.value
        }
        
        // Create new task and store it
        let task = Task<Response, Error> {
            try await execute()
        }
        
        inFlightRequests[key] = task
        
        do {
            let response = try await task.value
            inFlightRequests[key] = nil
            return response
        } catch {
            inFlightRequests[key] = nil
            throw error
        }
    }
    
    /// Generates a deduplication key for a request.
    ///
    /// The key is based on the request's method, URL, headers, and body hash,
    /// ensuring identical requests share the same key.
    ///
    /// - Parameter request: The request to generate a key for.
    /// - Returns: A unique string representing the request.
    private func deduplicationKey(for request: Request) -> String {
        var components: [String] = [
            request.method.rawValue,
            request.url.absoluteString
        ]
        
        // Include sorted headers
        let sortedHeaders = request.headers.all.sorted { $0.key < $1.key }
        for (key, value) in sortedHeaders {
            components.append("\(key):\(value)")
        }
        
        // Include body hash if present
        if let body = request.body {
            components.append("body:\(bodyHash(body))")
        }
        
        return components.joined(separator: "|")
    }
    
    /// Computes a hash for a request body.
    ///
    /// - Parameter body: The request body to hash.
    /// - Returns: A string representation of the body's hash.
    private func bodyHash(_ body: RequestBody) -> String {
        switch body {
        case .data(let data, _):
            return String(data.hashValue)
            
        case .json(let encodable, _):
            // Best-effort encoding for hash
            let anyEncodable = AnyEncodableWrapper(encodable)
            let encoded = (try? JSONEncoder().encode(anyEncodable)) ?? Data()
            return String(encoded.hashValue)
            
        case .form(let fields):
            return fields.sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
            
        case .multipart(let parts):
            return parts.map { $0.name }.joined(separator: ",")
        }
    }
    
    /// Clears all in-flight requests.
    ///
    /// This method is useful for testing or resetting the deduplicator state.
    public func clear() {
        inFlightRequests.removeAll()
    }
}

// MARK: - AnyEncodableWrapper

/// A type-erased wrapper for any `Encodable & Sendable` value.
///
/// Used internally for hashing JSON request bodies.
private struct AnyEncodableWrapper: Encodable, Sendable {
    private let _encode: @Sendable (Encoder) throws -> Void
    
    init(_ encodable: any Encodable & Sendable) {
        self._encode = { encoder in
            try encodable.encode(to: encoder)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
