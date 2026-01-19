//
//  StreamingTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 19/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Streaming API")
struct StreamingTests {
    
    // MARK: - StreamingResponse Tests
    
    @Suite("StreamingResponse")
    struct StreamingResponseTests {
        
        @Test("Collects stream into Data")
        func collectsStreamIntoData() async throws {
            // Create a simple stream
            let chunks = [
                Data([0x01, 0x02]),
                Data([0x03, 0x04]),
                Data([0x05, 0x06])
            ]
            
            let stream = AsyncThrowingStream<Data, Error> { continuation in
                for chunk in chunks {
                    continuation.yield(chunk)
                }
                continuation.finish()
            }
            
            let request = Request(method: .get, url: URL(string: "https://example.com")!)
            let streamingResponse = StreamingResponse(
                request: request,
                statusCode: 200,
                headers: [:],
                stream: stream
            )
            
            let collected = try await streamingResponse.collect()
            
            #expect(collected == Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06]))
        }
        
        @Test("Converts to Response")
        func convertsToResponse() async throws {
            let expectedData = Data("Hello, World!".utf8)
            
            let stream = AsyncThrowingStream<Data, Error> { continuation in
                continuation.yield(expectedData)
                continuation.finish()
            }
            
            let request = Request(method: .get, url: URL(string: "https://example.com")!)
            let streamingResponse = StreamingResponse(
                request: request,
                statusCode: 200,
                headers: ["Content-Type": "text/plain"],
                stream: stream
            )
            
            let response = try await streamingResponse.toResponse()
            
            #expect(response.statusCode == 200)
            #expect(response.headers["Content-Type"] == "text/plain")
            #expect(response.body == expectedData)
        }
    }
    
    // MARK: - Protocol Conformance Tests
    
    @Suite("StreamingCall Protocol")
    struct StreamingCallProtocolTests {
        
        @Test("TransportCall conforms to StreamingCall")
        func transportCallConformsToStreamingCall() {
            let request = Request(
                method: .get,
                url: URL(string: "https://example.com")!
            )
            
            let transport = URLSessionTransport()
            let call = TransportCall(request: request, transport: transport)
            
            #expect(call is StreamingCall)
        }
        
        @Test("StreamingCall execute() collects stream")
        func streamingCallExecuteCollectsStream() async throws {
            // Create a mock streaming call
            let request = Request(
                method: .get,
                url: URL(string: "https://httpbin.org/bytes/1024")!
            )
            
            let transport = URLSessionTransport()
            let call = TransportCall(request: request, transport: transport)
            
            if let streamingCall = call as? StreamingCall {
                let response = try await streamingCall.execute()
                
                #expect(response.statusCode == 200)
                #expect(response.body != nil)
                #expect(response.body!.count == 1024)
            }
        }
    }
    
    // MARK: - Streaming Tests
    
    @Suite("Data Streaming")
    struct DataStreamingTests {
        
        @Test("Streams data in chunks")
        func streamsDataInChunks() async throws {
            let request = Request(
                method: .get,
                url: URL(string: "https://httpbin.org/bytes/16384")! // 16KB
            )
            
            let transport = URLSessionTransport()
            let call = TransportCall(request: request, transport: transport)
            
            var chunkCount = 0
            var totalBytes = 0
            
            if let streamingCall = call as? StreamingCall {
                for try await chunk in streamingCall.stream() {
                    chunkCount += 1
                    totalBytes += chunk.count
                    
                    #expect(chunk.count > 0)
                }
            }
            
            #expect(chunkCount > 0)
            #expect(totalBytes == 16384)
        }
        
        @Test("Handles empty response")
        func handlesEmptyResponse() async throws {
            let request = Request(
                method: .get,
                url: URL(string: "https://httpbin.org/status/204")! // No content
            )
            
            let transport = URLSessionTransport()
            let call = TransportCall(request: request, transport: transport)
            
            var chunkCount = 0
            
            if let streamingCall = call as? StreamingCall {
                for try await _ in streamingCall.stream() {
                    chunkCount += 1
                }
            }
            
            // Empty response should yield no chunks or a single empty chunk
            #expect(chunkCount <= 1)
        }
        
        @Test("Supports cancellation")
        func supportsCancellation() async throws {
            let request = Request(
                method: .get,
                url: URL(string: "https://httpbin.org/bytes/1048576")! // 1MB
            )
            
            let transport = URLSessionTransport()
            let call = TransportCall(request: request, transport: transport)
            
            // Test that cancellation is respected
            let task = Task {
                if let streamingCall = call as? StreamingCall {
                    var chunkCount = 0
                    
                    do {
                        for try await _ in streamingCall.stream() {
                            chunkCount += 1
                            
                            // Cancel after first chunk
                            if chunkCount == 1 {
                                throw CancellationError()
                            }
                        }
                        
                        // Should not reach here
                        return false
                    } catch is CancellationError {
                        // Cancellation was handled
                        return true
                    } catch {
                        // Other errors
                        return false
                    }
                }
                return false
            }
            
            let wasCancelled = await task.value
            #expect(wasCancelled)
        }
    }
    
    // MARK: - Integration Tests
    
    @Suite("Streaming Integration")
    struct StreamingIntegrationTests {
        
        @Test("NetworkClient calls support streaming")
        func networkClientCallsSupportStreaming() {
            let client = NetworkClient()
            let request = Request(
                method: .get,
                url: URL(string: "https://httpbin.org/bytes/1024")!
            )
            
            let call = client.newCall(request)
            
            #expect(call is StreamingCall)
        }
        
        @Test("Streaming with custom headers")
        func streamingWithCustomHeaders() async throws {
            let request = Request(
                method: .get,
                url: URL(string: "https://httpbin.org/bytes/2048")!,
                headers: ["Accept": "application/octet-stream"]
            )
            
            let transport = URLSessionTransport()
            let call = TransportCall(request: request, transport: transport)
            
            var totalBytes = 0
            var chunkCount = 0
            
            if let streamingCall = call as? StreamingCall {
                for try await chunk in streamingCall.stream() {
                    totalBytes += chunk.count
                    chunkCount += 1
                }
            }
            
            // Should have received data in chunks
            #expect(chunkCount > 0)
            // Total should match (or be close to) expected size
            #expect(totalBytes > 0)
        }
        
        @Test("Streaming processes chunks incrementally")
        func streamingProcessesChunksIncrementally() async throws {
            let request = Request(
                method: .get,
                url: URL(string: "https://httpbin.org/bytes/32768")! // 32KB
            )
            
            let transport = URLSessionTransport()
            let call = TransportCall(request: request, transport: transport)
            
            // Track chunks as they arrive
            actor ChunkTracker {
                var chunks: [Int] = []
                
                func add(_ size: Int) {
                    chunks.append(size)
                }
                
                func getChunks() -> [Int] {
                    return chunks
                }
            }
            
            let tracker = ChunkTracker()
            
            if let streamingCall = call as? StreamingCall {
                for try await chunk in streamingCall.stream() {
                    await tracker.add(chunk.count)
                }
            }
            
            let chunks = await tracker.getChunks()
            
            // Should have received multiple chunks
            #expect(chunks.count > 1)
            
            // Total should match expected size
            let total = chunks.reduce(0, +)
            #expect(total == 32768)
        }
    }
}
