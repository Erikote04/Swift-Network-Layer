//
//  RequestBuilderTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 19/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

// MARK: - Test Models

fileprivate struct Product: Codable, Sendable {
    let id: Int
    let name: String
    let price: Double
}

// MARK: - RequestBuilder Tests

@Suite("RequestBuilder with RequestBody")
struct RequestBuilderTests {
    
    @Test("Builder constructs request with RequestBody")
    func builderConstructsRequestWithBody() {
        var builder = RequestBuilder(
            method: .post,
            url: URL(string: "https://api.example.com/products")!
        )
        
        let product = Product(id: 1, name: "Widget", price: 9.99)
        let request = builder
            .jsonBody(product)
            .build()
        
        #expect(request.body != nil)
        
        if case .json = request.body {
            // Success - body is JSON type
        } else {
            Issue.record("Expected JSON body")
        }
    }
    
    @Test("Builder sets JSON body correctly")
    func builderSetsJSONBody() {
        var builder = RequestBuilder(
            method: .post,
            url: URL(string: "https://example.com")!
        )
        
        let dict = ["key": "value"]
        let request = builder
            .jsonBody(dict)
            .build()
        
        #expect(request.body != nil)
        #expect(request.body?.contentType == "application/json; charset=utf-8")
    }
    
    @Test("Builder sets form body correctly")
    func builderSetsFormBody() {
        var builder = RequestBuilder(
            method: .post,
            url: URL(string: "https://example.com/form")!
        )
        
        let request = builder
            .formBody(["username": "alice", "password": "secret"])
            .build()
        
        #expect(request.body != nil)
        #expect(request.body?.contentType == "application/x-www-form-urlencoded")
    }
    
    @Test("Builder sets raw data body correctly")
    func builderSetsDataBody() {
        var builder = RequestBuilder(
            method: .post,
            url: URL(string: "https://example.com/upload")!
        )
        
        let imageData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let request = builder
            .body(imageData, contentType: "image/jpeg")
            .build()
        
        #expect(request.body != nil)
        #expect(request.body?.contentType == "image/jpeg")
    }
    
    @Test("Builder handles nil body")
    func builderHandlesNilBody() {
        var builder = RequestBuilder(
            method: .get,
            url: URL(string: "https://example.com")!
        )
        
        let request = builder
            .body(nil as Data?)
            .build()
        
        #expect(request.body == nil)
    }
    
    @Test("Builder allows direct RequestBody setting")
    func builderAllowsDirectBodySetting() {
        var builder = RequestBuilder(
            method: .post,
            url: URL(string: "https://example.com")!
        )
        
        let body = RequestBody.json(["test": "value"])
        let request = builder
            .body(body)
            .build()
        
        #expect(request.body != nil)
    }
    
    @Test("Builder fluent API chains correctly")
    func builderFluentAPIChains() {
        let user = Product(id: 42, name: "Test", price: 19.99)
        
        var builder = RequestBuilder(
            method: .post,
            url: URL(string: "https://api.example.com/users")!
        )
        
        _ = builder.header("Authorization", "Bearer token123")
        _ = builder.header("X-Custom-Header", "custom-value")
        _ = builder.jsonBody(user)
        _ = builder.timeout(30)
        _ = builder.cachePolicy(.reloadIgnoringCache)
        
        let request = builder.build()
        
        #expect(request.method == .post)
        #expect(request.headers["Authorization"] == "Bearer token123")
        #expect(request.headers["X-Custom-Header"] == "custom-value")
        #expect(request.body != nil)
        #expect(request.timeout == 30)
        #expect(request.cachePolicy == .reloadIgnoringCache)
    }
    
    @Test("Builder uses default content type for raw data")
    func builderUsesDefaultContentType() {
        var builder = RequestBuilder(
            method: .post,
            url: URL(string: "https://example.com")!
        )
        
        let request = builder
            .body(Data([0x01, 0x02]))
            .build()
        
        #expect(request.body?.contentType == "application/octet-stream")
    }
    
    @Test("Builder custom encoder is respected")
    func builderCustomEncoderRespected() {
        var builder = RequestBuilder(
            method: .post,
            url: URL(string: "https://example.com")!
        )
        
        let customEncoder = JSONEncoder()
        customEncoder.outputFormatting = .prettyPrinted
        
        let request = builder
            .jsonBody(["key": "value"], encoder: customEncoder)
            .build()
        
        #expect(request.body != nil)
        
        // Verify encoding works (will use custom encoder)
        if let body = request.body {
            let encoded = try? body.encoded()
            #expect(encoded != nil)
        }
    }
}
