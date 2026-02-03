//
//  StreamingCall.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 19/1/26.
//

import Foundation

/// A protocol for calls that support streaming response data.
///
/// `StreamingCall` extends the basic `Call` protocol with the ability to
/// stream response data as an `AsyncSequence` of chunks, rather than
/// accumulating all data in memory before returning.
///
/// Useful for:
/// - Large file downloads
/// - Streaming APIs (Server-Sent Events, NDJSON)
/// - Processing data incrementally
/// - Reducing memory footprint
///
/// ## Example Usage
///
/// ```swift
/// let call = client.newCall(downloadRequest)
///
/// if let streamingCall = call as? StreamingCall {
///     for try await chunk in streamingCall.stream() {
///         // Process each chunk as it arrives
///         print("Received \(chunk.count) bytes")
///         processChunk(chunk)
///     }
/// }
/// ```
///
/// ## Memory Management
///
/// Unlike `execute()` which loads the entire response into memory,
/// `stream()` allows processing data incrementally, which is crucial
/// for large responses or memory-constrained environments.
public protocol StreamingCall: Call {
    
    /// Streams the response data as an asynchronous sequence of chunks.
    ///
    /// Each chunk represents a portion of the response body received from
    /// the server. Chunks are delivered as they arrive, allowing incremental
    /// processing without loading the entire response into memory.
    ///
    /// - Returns: An `AsyncThrowingStream` that yields `Data` chunks.
    /// - Throws: Any error encountered during the request or streaming.
    ///
    /// ## Important Notes
    ///
    /// - The stream begins immediately upon iteration
    /// - Response headers are not available until the first chunk
    /// - Cancellation is supported via task cancellation
    /// - The stream completes when all data is received or an error occurs
    ///
    /// ## Cancellation
    ///
    /// The stream respects task cancellation. If the task is cancelled
    /// while iterating, the stream will throw `CancellationError` and
    /// clean up resources.
    func stream() -> AsyncThrowingStream<Data, Error>
}

// MARK: - Streaming Response

/// Represents a streaming response with metadata and data stream.
///
/// `StreamingResponse` provides access to response headers and status code
/// before starting to consume the body stream. This allows decisions about
/// stream processing to be made based on response metadata.
public struct StreamingResponse: Sendable {
    
    /// The original request.
    public let request: Request
    
    /// The HTTP status code.
    public let statusCode: Int
    
    /// The response headers.
    public let headers: HTTPHeaders
    
    /// The stream of response body chunks.
    public let stream: AsyncThrowingStream<Data, Error>
    
    /// Creates a new streaming response.
    ///
    /// - Parameters:
    ///   - request: The original request.
    ///   - statusCode: The HTTP status code.
    ///   - headers: The response headers.
    ///   - stream: The data stream.
    public init(
        request: Request,
        statusCode: Int,
        headers: HTTPHeaders,
        stream: AsyncThrowingStream<Data, Error>
    ) {
        self.request = request
        self.statusCode = statusCode
        self.headers = headers
        self.stream = stream
    }
    
    /// Collects the entire stream into a single `Data` instance.
    ///
    /// This is a convenience method for cases where you want to use the
    /// streaming API but still need the complete data. It accumulates all
    /// chunks in memory.
    ///
    /// - Returns: The complete response body.
    /// - Throws: Any error encountered during streaming.
    ///
    /// - Warning: This loads the entire response into memory, defeating
    ///   the purpose of streaming for large responses.
    public func collect() async throws -> Data {
        var accumulated = Data()
        
        for try await chunk in stream {
            accumulated.append(chunk)
        }
        
        return accumulated
    }
    
    /// Converts the streaming response to a regular `Response`.
    ///
    /// This collects all chunks and creates a standard `Response` object.
    /// Useful when you need to work with APIs that expect a `Response`
    /// but want to use streaming internally.
    ///
    /// - Returns: A complete `Response` with the full body.
    /// - Throws: Any error encountered during streaming.
    public func toResponse() async throws -> Response {
        let body = try await collect()
        
        return Response(
            request: request,
            statusCode: statusCode,
            headers: headers,
            body: body
        )
    }
}

// MARK: - Default Implementation

extension StreamingCall {
    
    /// Executes the call and collects the entire stream into a `Response`.
    ///
    /// This default implementation satisfies the `Call` protocol requirement
    /// by consuming the entire stream and returning a standard response.
    ///
    /// - Returns: The resulting `Response` with the complete body.
    /// - Throws: Any error encountered during execution or streaming.
    public func execute() async throws -> Response {
        // Create a temporary streaming response
        let streamingResponse = await streamWithMetadata()
        
        // Collect and convert to Response
        return try await streamingResponse.toResponse()
    }
    
    /// Streams the response with metadata (internal helper).
    ///
    /// This is an internal helper that subclasses can override to provide
    /// streaming with response metadata available upfront.
    ///
    /// - Returns: A `StreamingResponse` with headers and stream.
    func streamWithMetadata() async -> StreamingResponse {
        // Default implementation: create a simple stream
        // Subclasses should override this to provide proper metadata
        return StreamingResponse(
            request: request,
            statusCode: 200,
            headers: [:],
            stream: stream()
        )
    }
}
