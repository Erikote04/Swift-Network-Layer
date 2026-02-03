//
//  MultipartFormDataTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 19/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("MultipartFormData", .tags(.multipart))
struct MultipartFormDataTests {
    
    // MARK: - Creation Tests
    
    @Suite("Part Creation")
    struct PartCreationTests {
        
        @Test("Creates text field correctly")
        func createsTextField() {
            let part = MultipartFormData(name: "username", value: "alice")
            
            #expect(part.name == "username")
            #expect(part.filename == nil)
            #expect(part.mimeType == "text/plain; charset=utf-8")
            #expect(String(data: part.data, encoding: .utf8) == "alice")
        }
        
        @Test("Creates file upload with filename")
        func createsFileUpload() {
            let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // JPEG magic bytes
            let part = MultipartFormData(
                name: "avatar",
                filename: "profile.jpg",
                data: imageData,
                mimeType: "image/jpeg"
            )
            
            #expect(part.name == "avatar")
            #expect(part.filename == "profile.jpg")
            #expect(part.mimeType == "image/jpeg")
            #expect(part.data == imageData)
        }
        
        @Test("Creates data part without filename")
        func createsDataPart() {
            let pdfData = Data([0x25, 0x50, 0x44, 0x46]) // PDF magic bytes
            let part = MultipartFormData(
                name: "document",
                data: pdfData,
                mimeType: "application/pdf"
            )
            
            #expect(part.name == "document")
            #expect(part.filename == nil)
            #expect(part.mimeType == "application/pdf")
            #expect(part.data == pdfData)
        }
        
        @Test("Uses default MIME type for file upload")
        func usesDefaultMimeType() {
            let part = MultipartFormData(
                name: "file",
                filename: "unknown.bin",
                data: Data()
            )
            
            #expect(part.mimeType == "application/octet-stream")
        }
    }
    
    // MARK: - Encoding Tests
    
    @Suite("Encoding")
    struct EncodingTests {
        
        @Test("Encodes text field correctly")
        func encodesTextField() {
            let part = MultipartFormData(name: "email", value: "user@example.com")
            let boundary = "TestBoundary123"
            
            let encoded = part.encode(boundary: boundary)
            let encodedString = String(data: encoded, encoding: .utf8)!
            
            #expect(encodedString.contains("--TestBoundary123"))
            #expect(encodedString.contains("Content-Disposition: form-data; name=\"email\""))
            #expect(encodedString.contains("Content-Type: text/plain; charset=utf-8"))
            #expect(encodedString.contains("user@example.com"))
        }
        
        @Test("Encodes file upload with filename")
        func encodesFileUpload() {
            let imageData = Data("fake-image-data".utf8)
            let part = MultipartFormData(
                name: "photo",
                filename: "vacation.jpg",
                data: imageData,
                mimeType: "image/jpeg"
            )
            let boundary = "TestBoundary456"
            
            let encoded = part.encode(boundary: boundary)
            let encodedString = String(data: encoded, encoding: .utf8)!
            
            #expect(encodedString.contains("--TestBoundary456"))
            #expect(encodedString.contains("Content-Disposition: form-data; name=\"photo\"; filename=\"vacation.jpg\""))
            #expect(encodedString.contains("Content-Type: image/jpeg"))
            #expect(encodedString.contains("fake-image-data"))
        }
        
        @Test("Includes proper line endings")
        func includesProperLineEndings() {
            let part = MultipartFormData(name: "test", value: "data")
            let boundary = "Boundary"
            
            let encoded = part.encode(boundary: boundary)
            let encodedString = String(data: encoded, encoding: .utf8)!
            
            // Check for CRLF (\r\n) line endings
            #expect(encodedString.contains("\r\n"))
            #expect(encodedString.hasSuffix("\r\n"))
        }
    }
    
    // MARK: - Boundary Generation Tests
    
    @Suite("Boundary Generation")
    struct BoundaryGenerationTests {
        
        @Test("Generates unique boundaries")
        func generatesUniqueBoundaries() {
            let boundary1 = MultipartFormData.generateBoundary()
            let boundary2 = MultipartFormData.generateBoundary()
            
            #expect(boundary1 != boundary2)
        }
        
        @Test("Boundary has correct format")
        func boundaryHasCorrectFormat() {
            let boundary = MultipartFormData.generateBoundary()
            
            #expect(boundary.hasPrefix("Boundary-"))
            #expect(boundary.count > 10) // UUID-based, should be long
        }
        
        @Test("Generates 10 unique boundaries", arguments: 1...10)
        func generatesMultipleUniqueBoundaries(iteration: Int) {
            let boundaries = (0..<10).map { _ in MultipartFormData.generateBoundary() }
            let uniqueBoundaries = Set(boundaries)
            
            #expect(uniqueBoundaries.count == 10)
        }
    }
    
    // MARK: - RequestBody Integration Tests
    
    @Suite("RequestBody Integration")
    struct RequestBodyIntegrationTests {
        
        @Test("RequestBody.multipart encodes correctly")
        func requestBodyMultipartEncodes() throws {
            let parts = [
                MultipartFormData(name: "title", value: "My Upload"),
                MultipartFormData(
                    name: "file",
                    filename: "document.txt",
                    data: Data("file content".utf8),
                    mimeType: "text/plain"
                )
            ]
            
            let body = RequestBody.multipart(parts)
            let (encodedData, boundary) = try body.encodedWithBoundary()
            
            #expect(boundary != nil)
            
            let encodedString = String(data: encodedData, encoding: .utf8)!
            
            // Check structure
            #expect(encodedString.contains("--\(boundary!)"))
            #expect(encodedString.contains("Content-Disposition: form-data; name=\"title\""))
            #expect(encodedString.contains("Content-Disposition: form-data; name=\"file\"; filename=\"document.txt\""))
            #expect(encodedString.contains("My Upload"))
            #expect(encodedString.contains("file content"))
            #expect(encodedString.hasSuffix("--\(boundary!)--\r\n"))
        }
        
        @Test("Multipart content type is correct")
        func multipartContentTypeCorrect() {
            let body = RequestBody.multipart([
                MultipartFormData(name: "test", value: "data")
            ])
            
            #expect(body.contentType == "multipart/form-data")
        }
        
        @Test("Empty multipart body encodes correctly")
        func emptyMultipartEncodes() throws {
            let body = RequestBody.multipart([])
            let (encodedData, boundary) = try body.encodedWithBoundary()
            
            #expect(boundary != nil)
            
            let encodedString = String(data: encodedData, encoding: .utf8)!
            
            // Should only contain final boundary
            #expect(encodedString == "--\(boundary!)--\r\n")
        }
    }
}
