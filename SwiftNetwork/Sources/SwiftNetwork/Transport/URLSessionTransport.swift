//
//  URLSessionTransport.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// A `Transport` implementation backed by `URLSession`.
///
/// `URLSessionTransport` adapts SwiftNetwork requests to `URLSession`,
/// handling request conversion, execution, response mapping, optional
/// progress reporting, certificate pinning, and request prioritization.
///
/// - Safety: `URLSessionTransport` is actor-isolated, ensuring access to its
///   mutable state is serialized by the actor runtime.
actor URLSessionTransport: Transport, ProgressReportingTransport, StreamingTransport {

    private let session: URLSession
    private let delegate: PinningURLSessionDelegate?

    /// Creates a new URLSession-based transport.
    ///
    /// - Parameters:
    ///   - session: The URLSession instance used to perform requests.
    ///   - certificatePinner: Optional certificate pinner for HTTPS validation.
    init(
        session: URLSession = .shared,
        certificatePinner: CertificatePinner? = nil
    ) {
        if let pinner = certificatePinner {
            // Create delegate for pinning
            let delegate = PinningURLSessionDelegate(pinner: pinner)
            self.delegate = delegate
            
            // Create session with delegate
            let configuration = session.configuration
            self.session = URLSession(
                configuration: configuration,
                delegate: delegate,
                delegateQueue: nil
            )
        } else {
            self.session = session
            self.delegate = nil
        }
    }

    /// Executes a request using `URLSession`.
    ///
    /// - Parameter request: The request to execute.
    /// - Returns: A `Response` containing the server response.
    /// - Throws: A `NetworkError` if execution fails, is cancelled,
    ///   or the response is invalid.
    func execute(_ request: Request) async throws -> Response {
        try await execute(request, progress: nil)
    }
    
    /// Executes a request with optional progress reporting.
    ///
    /// - Parameters:
    ///   - request: The request to execute.
    ///   - progress: An optional closure to receive progress updates.
    /// - Returns: A `Response` containing the server response.
    /// - Throws: A `NetworkError` if execution fails, is cancelled,
    ///   or the response is invalid.
    func execute(
        _ request: Request,
        progress: (@Sendable (Progress) -> Void)?
    ) async throws -> Response {
        let urlRequest = try makeURLRequest(from: request)

        do {
            // If progress reporting is requested, use delegate-based approach
            if let progressHandler = progress {
                return try await executeWithProgress(urlRequest, request: request, progress: progressHandler)
            }
            
            // Otherwise, use the simpler data task API with priority support
            return try await executeWithPriority(urlRequest, request: request)
        } catch is CancellationError {
            throw NetworkError.cancelled
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.transportError(error)
        }
    }
    
    /// Executes a request with priority scheduling.
    ///
    /// - Parameters:
    ///   - urlRequest: The URLRequest to execute.
    ///   - request: The original SwiftNetwork request.
    /// - Returns: A `Response` containing the server response.
    /// - Throws: A `NetworkError` if execution fails.
    private func executeWithPriority(
        _ urlRequest: URLRequest,
        request: Request
    ) async throws -> Response {
        try await withTaskPriority(request.priority.swiftTaskPriority) { [session] in
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            return Response(
                request: request,
                statusCode: httpResponse.statusCode,
                headers: HTTPHeaders(httpResponse.allHeaderFields as? [String: String] ?? [:]),
                body: data
            )
        }
    }
    
    /// Executes a request and streams the response data.
    ///
    /// - Parameter request: The request to execute.
    /// - Returns: A `StreamingResponse` with metadata and data stream.
    /// - Throws: A `NetworkError` if execution fails or is cancelled.
    func stream(_ request: Request) async throws -> StreamingResponse {
        let urlRequest = try makeURLRequest(from: request)
        
        // Execute with proper priority
        return try await withTaskPriority(request.priority.swiftTaskPriority) { [session] in
            // Use bytes(for:) API which returns AsyncSequence
            let (bytes, response) = try await session.bytes(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            // Convert AsyncSequence<UInt8> to AsyncThrowingStream<Data>
            let stream = AsyncThrowingStream<Data, Error> { continuation in
                Task {
                    do {
                        var buffer = Data()
                        buffer.reserveCapacity(8192) // 8KB buffer
                        
                        for try await byte in bytes {
                            buffer.append(byte)
                            
                            // Yield chunks of ~8KB
                            if buffer.count >= 8192 {
                                continuation.yield(buffer)
                                buffer = Data()
                                buffer.reserveCapacity(8192)
                            }
                        }
                        
                        // Yield remaining data
                        if !buffer.isEmpty {
                            continuation.yield(buffer)
                        }
                        
                        continuation.finish()
                    } catch is CancellationError {
                        continuation.finish(throwing: NetworkError.cancelled)
                    } catch {
                        continuation.finish(throwing: NetworkError.transportError(error))
                    }
                }
            }
            
            return StreamingResponse(
                request: request,
                statusCode: httpResponse.statusCode,
                headers: HTTPHeaders(httpResponse.allHeaderFields as? [String: String] ?? [:]),
                stream: stream
            )
        }
    }
    
    /// Executes a request with progress tracking using URLSessionDelegate.
    ///
    /// - Parameters:
    ///   - urlRequest: The URLRequest to execute.
    ///   - request: The original SwiftNetwork request.
    ///   - progress: A closure to receive progress updates.
    /// - Returns: A `Response` containing the server response.
    /// - Throws: A `NetworkError` if execution fails.
    private func executeWithProgress(
        _ urlRequest: URLRequest,
        request: Request,
        progress: @escaping @Sendable (Progress) -> Void
    ) async throws -> Response {
        try await withTaskPriority(request.priority.swiftTaskPriority) { [session] in
            let delegate = ProgressDelegate(progressHandler: progress)
            let delegateSession = URLSession(
                configuration: session.configuration,
                delegate: delegate,
                delegateQueue: nil
            )
            
            defer {
                delegateSession.finishTasksAndInvalidate()
            }
            
            let (data, response) = try await delegateSession.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            return Response(
                request: request,
                statusCode: httpResponse.statusCode,
                headers: HTTPHeaders(httpResponse.allHeaderFields as? [String: String] ?? [:]),
                body: data
            )
        }
    }

    /// Converts a `Request` into a `URLRequest`.
    ///
    /// - Parameter request: The SwiftNetwork request to convert.
    /// - Returns: A configured `URLRequest`.
    /// - Throws: An error if request construction or body encoding fails.
    private func makeURLRequest(from request: Request) throws -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = request.timeout ?? urlRequest.timeoutInterval
        
        // Encode the body if present
        if let body = request.body {
            let (encodedData, boundary) = try body.encodedWithBoundary()
            urlRequest.httpBody = encodedData
            
            // Set Content-Type header if not already provided
            if request.headers["Content-Type"] == nil {
                var contentType = body.contentType
                
                // For multipart, append the boundary
                if let boundary = boundary {
                    contentType += "; boundary=\(boundary)"
                }
                
                urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
            }
        }

        // Apply all headers from the request
        for (key, value) in request.headers.all {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        return urlRequest
    }
}

// MARK: - Progress Delegate

/// A URLSessionTaskDelegate that tracks and reports upload/download progress.
private final class ProgressDelegate: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    private let progressHandler: @Sendable (Progress) -> Void
    
    init(progressHandler: @escaping @Sendable (Progress) -> Void) {
        self.progressHandler = progressHandler
    }
    
    // MARK: - Upload Progress
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        let progress = Progress(
            bytesTransferred: totalBytesSent,
            totalBytes: totalBytesExpectedToSend
        )
        progressHandler(progress)
    }
    
    // MARK: - Download Progress
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        completionHandler(.allow)
    }
    
    // Note: For download progress, we would need to accumulate data manually
    // since URLSession.data(for:) handles data accumulation internally.
    // For now, we focus on upload progress which is more common for multipart uploads.
}
