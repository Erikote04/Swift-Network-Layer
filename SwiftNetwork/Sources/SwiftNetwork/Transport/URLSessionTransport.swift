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
/// handling request conversion, execution, response mapping, and optional
/// progress reporting.
final class URLSessionTransport: Transport {

    private let session: URLSession

    /// Creates a new URLSession-based transport.
    ///
    /// - Parameter session: The URLSession instance used to perform requests.
    ///   Defaults to `URLSession.shared`.
    init(session: URLSession = .shared) {
        self.session = session
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
            
            // Otherwise, use the simpler data task API
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
        } catch is CancellationError {
            throw NetworkError.cancelled
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.transportError(error)
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
