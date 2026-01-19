//
//  ProgressTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 19/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Progress Reporting")
struct ProgressTests {
    
    // MARK: - Progress Struct Tests
    
    @Suite("Progress Calculation")
    struct ProgressCalculationTests {
        
        @Test("Calculates fraction completed correctly")
        func calculatesFractionCompleted() {
            let progress = Progress(bytesTransferred: 50, totalBytes: 100)
            
            #expect(progress.fractionCompleted == 0.5)
        }
        
        @Test("Returns 0 for unknown total bytes")
        func returnsZeroForUnknownTotal() {
            let progress = Progress(bytesTransferred: 50, totalBytes: -1)
            
            #expect(progress.fractionCompleted == 0.0)
        }
        
        @Test("Returns 0 for zero total bytes")
        func returnsZeroForZeroTotal() {
            let progress = Progress(bytesTransferred: 0, totalBytes: 0)
            
            #expect(progress.fractionCompleted == 0.0)
        }
        
        @Test("Handles 100% completion")
        func handlesFullCompletion() {
            let progress = Progress(bytesTransferred: 1024, totalBytes: 1024)
            
            #expect(progress.fractionCompleted == 1.0)
        }
        
        @Test("Handles partial progress", arguments: [
            (bytes: Int64(25), total: Int64(100), expected: 0.25),
            (bytes: Int64(75), total: Int64(100), expected: 0.75),
            (bytes: Int64(1), total: Int64(10), expected: 0.1)
        ])
        func handlesPartialProgress(bytes: Int64, total: Int64, expected: Double) {
            let progress = Progress(bytesTransferred: bytes, totalBytes: total)
            
            #expect(progress.fractionCompleted == expected)
        }
    }
    
    // MARK: - Upload Progress Tests
    
    @Suite("Upload Progress")
    struct UploadProgressTests {
        
        @Test("Reports progress for multipart upload")
        func reportsProgressForMultipartUpload() async throws {
            // Create a large multipart upload
            let largeData = Data(repeating: 0xFF, count: 1024 * 100) // 100KB
            let parts = [
                MultipartFormData(name: "description", value: "Large file"),
                MultipartFormData(
                    name: "file",
                    filename: "large.bin",
                    data: largeData,
                    mimeType: "application/octet-stream"
                )
            ]
            
            let request = Request(
                method: .post,
                url: URL(string: "https://httpbin.org/post")!,
                body: .multipart(parts)
            )
            
            let transport = URLSessionTransport()
            let call = TransportCall(request: request, transport: transport)
            
            // Use confirmation to validate progress callbacks
            await confirmation("Progress callback is invoked") { confirm in
                if let progressCall = call as? ProgressCall {
                    _ = try? await progressCall.execute { progress in
                        // Progress callback was invoked
                        confirm()
                    }
                }
            }
        }
        
        @Test("Progress increases monotonically")
        func progressIncreasesMonotonically() async throws {
            let largeData = Data(repeating: 0xAA, count: 1024 * 50) // 50KB
            let parts = [
                MultipartFormData(
                    name: "file",
                    filename: "data.bin",
                    data: largeData,
                    mimeType: "application/octet-stream"
                )
            ]
            
            let request = Request(
                method: .post,
                url: URL(string: "https://httpbin.org/post")!,
                body: .multipart(parts)
            )
            
            let transport = URLSessionTransport()
            let call = TransportCall(request: request, transport: transport)
            
            // Use an actor to safely track progress
            actor ProgressTracker {
                var previousBytes: Int64 = 0
                
                func update(_ newBytes: Int64) -> Bool {
                    let isValid = newBytes >= previousBytes
                    previousBytes = newBytes
                    return isValid
                }
            }
            
            let tracker = ProgressTracker()
            
            if let progressCall = call as? ProgressCall {
                _ = try? await progressCall.execute { progress in
                    // Bytes should never decrease
                    Task {
                        let isValid = await tracker.update(progress.bytesTransferred)
                        #expect(isValid)
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Call Protocol Tests
    
    @Suite("ProgressCall Protocol")
    struct ProgressCallProtocolTests {
        
        @Test("TransportCall conforms to ProgressCall")
        func transportCallConformsToProgressCall() {
            let request = Request(
                method: .get,
                url: URL(string: "https://example.com")!
            )
            
            let transport = URLSessionTransport()
            let call = TransportCall(request: request, transport: transport)
            
            #expect(call is ProgressCall)
        }
        
        @Test("InterceptorCall conforms to ProgressCall")
        func interceptorCallConformsToProgressCall() {
            let request = Request(
                method: .get,
                url: URL(string: "https://example.com")!
            )
            
            let transport = URLSessionTransport()
            let call = InterceptorCall(
                request: request,
                interceptors: [],
                transport: transport
            )
            
            #expect(call is ProgressCall)
        }
        
        @Test("ProgressCall execute() calls base implementation")
        func progressCallExecuteCallsBase() async throws {
            let request = Request(
                method: .get,
                url: URL(string: "https://httpbin.org/get")!
            )
            
            let transport = URLSessionTransport()
            let call = TransportCall(request: request, transport: transport)
            
            // Execute without progress should work
            let response = try await call.execute()
            
            #expect(response.statusCode == 200)
        }
    }
    
    // MARK: - Integration Tests
    
    @Suite("Progress Integration")
    struct ProgressIntegrationTests {
        
        @Test("NetworkClient calls can be cast to ProgressCall")
        func networkClientCallsCanBeCastToProgressCall() {
            let client = NetworkClient()
            let request = Request(
                method: .post,
                url: URL(string: "https://httpbin.org/post")!,
                body: .json(["key": "value"])
            )
            
            let call = client.newCall(request)
            
            #expect(call is ProgressCall)
        }
        
        @Test("Progress works through interceptor chain")
        func progressWorksThroughInterceptorChain() async throws {
            let loggingInterceptor = LoggingInterceptor(level: .none)
            let config = NetworkClientConfiguration(interceptors: [loggingInterceptor])
            let client = NetworkClient(configuration: config)
            
            let largeData = Data(repeating: 0xBB, count: 1024 * 30) // 30KB
            let parts = [
                MultipartFormData(
                    name: "file",
                    filename: "test.bin",
                    data: largeData,
                    mimeType: "application/octet-stream"
                )
            ]
            
            let request = Request(
                method: .post,
                url: URL(string: "https://httpbin.org/post")!,
                body: .multipart(parts)
            )
            
            let call = client.newCall(request)
            
            await confirmation("Progress reported through interceptors") { confirm in
                if let progressCall = call as? ProgressCall {
                    _ = try? await progressCall.execute { _ in
                        confirm()
                    }
                }
            }
        }
    }
}
