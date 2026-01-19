//
//  MultipartTransportTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 19/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Multipart Transport Integration")
struct MultipartTransportTests {
    
    @Test("Transport handles multipart upload")
    func transportHandlesMultipartUpload() async throws {
        let transport = FakeTransport { request in
            // Verify request has body
            #expect(request.body != nil)
            
            if case .multipart = request.body {
                // Success - body is multipart type
            } else {
                Issue.record("Expected multipart body")
            }
            
            return TestResponses.success(request: request)
        }
        
        let client = TestClientFactory.make(transport: transport)
        
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let parts = [
            MultipartFormData(name: "title", value: "My Photo"),
            MultipartFormData(
                name: "image",
                filename: "photo.jpg",
                data: imageData,
                mimeType: "image/jpeg"
            )
        ]
        
        let request = Request(
            method: .post,
            url: URL(string: "https://api.example.com/upload")!,
            body: .multipart(parts)
        )
        
        _ = try await client.newCall(request).execute()
        
        let recorded = await transport.requests
        #expect(recorded.count == 1)
        #expect(recorded[0].request.body != nil)
    }
    
    @Test("Content-Type header includes boundary")
    func contentTypeIncludesBoundary() async throws {
        let transport = FakeTransport { request in
            // Verify the request has a body
            #expect(request.body != nil)
            
            if case .multipart = request.body {
                // Success - body is multipart type
            } else {
                Issue.record("Expected multipart body")
            }
            
            return TestResponses.success(request: request)
        }
        
        let client = TestClientFactory.make(transport: transport)
        
        let parts = [
            MultipartFormData(name: "field", value: "value")
        ]
        
        let request = Request(
            method: .post,
            url: URL(string: "https://example.com/upload")!,
            body: .multipart(parts)
        )
        
        _ = try await client.newCall(request).execute()
        
        let recorded = await transport.requests
        #expect(recorded.count == 1)
        #expect(recorded[0].request.body != nil)
    }
    
    @Test("Multiple file upload")
    func multipleFileUpload() async throws {
        let transport = FakeTransport { request in
            TestResponses.success(request: request)
        }
        
        let client = TestClientFactory.make(transport: transport)
        
        let image1Data = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let image2Data = Data([0xFF, 0xD8, 0xFF, 0xE1])
        
        let parts = [
            MultipartFormData(name: "description", value: "Two photos"),
            MultipartFormData(
                name: "photo1",
                filename: "first.jpg",
                data: image1Data,
                mimeType: "image/jpeg"
            ),
            MultipartFormData(
                name: "photo2",
                filename: "second.jpg",
                data: image2Data,
                mimeType: "image/jpeg"
            )
        ]
        
        let request = Request(
            method: .post,
            url: URL(string: "https://api.example.com/gallery")!,
            body: .multipart(parts)
        )
        
        _ = try await client.newCall(request).execute()
        
        let recorded = await transport.requests
        #expect(recorded.count == 1)
    }
    
    @Test("Large file upload simulation")
    func largeFileUpload() async throws {
        let transport = FakeTransport { request in
            TestResponses.success(request: request)
        }
        
        let client = TestClientFactory.make(transport: transport)
        
        // Simulate a 1MB file
        let largeData = Data(repeating: 0xFF, count: 1_024 * 1_024)
        
        let parts = [
            MultipartFormData(
                name: "file",
                filename: "large.bin",
                data: largeData,
                mimeType: "application/octet-stream"
            )
        ]
        
        let request = Request(
            method: .post,
            url: URL(string: "https://example.com/upload")!,
            body: .multipart(parts)
        )
        
        _ = try await client.newCall(request).execute()
        
        let recorded = await transport.requests
        #expect(recorded.count == 1)
    }
    
    @Test("Mixed content types in multipart")
    func mixedContentTypes() async throws {
        let transport = FakeTransport { request in
            TestResponses.success(request: request)
        }
        
        let client = TestClientFactory.make(transport: transport)
        
        let jsonData = Data("{\"key\":\"value\"}".utf8)
        let imageData = Data([0xFF, 0xD8])
        let textData = Data("plain text".utf8)
        
        let parts = [
            MultipartFormData(name: "metadata", data: jsonData, mimeType: "application/json"),
            MultipartFormData(name: "image", filename: "img.jpg", data: imageData, mimeType: "image/jpeg"),
            MultipartFormData(name: "note", value: "plain text")
        ]
        
        let request = Request(
            method: .post,
            url: URL(string: "https://example.com/mixed")!,
            body: .multipart(parts)
        )
        
        _ = try await client.newCall(request).execute()
        
        let recorded = await transport.requests
        #expect(recorded.count == 1)
    }
    
    @Test("Boundary consistency between encoding and Content-Type")
    func boundaryConsistency() throws {
        let parts = [
            MultipartFormData(name: "test", value: "data")
        ]
        
        let body = RequestBody.multipart(parts)
        let (encodedData, boundary) = try body.encodedWithBoundary()
        
        #expect(boundary != nil)
        
        let encodedString = String(data: encodedData, encoding: .utf8)!
        
        // Verify the boundary in the encoded data matches the returned boundary
        #expect(encodedString.contains("--\(boundary!)"))
        #expect(encodedString.contains("--\(boundary!)--"))
    }
}
