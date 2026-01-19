//
//  RequestBodyTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 19/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

// MARK: - Test Models

fileprivate struct TestUser: Codable, Sendable {
    let id: Int
    let name: String
    let email: String
}

fileprivate struct CustomEncodableType: Encodable, Sendable {
    let timestamp: Date
    let value: String
}

// MARK: - Request Body Tests

@Suite("RequestBody")
struct RequestBodyTests {
    
    // MARK: - Data Body Tests
    
    @Suite("Data Body Encoding")
    struct DataBodyTests {
        
        @Test("Encodes raw data correctly")
        func encodesRawData() throws {
            let originalData = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]) // "Hello"
            let body = RequestBody.data(originalData)
            
            let encoded = try body.encoded()
            
            #expect(encoded == originalData)
        }
        
        @Test("Provides default content type for raw data")
        func providesDefaultContentType() {
            let body = RequestBody.data(Data())
            
            #expect(body.contentType == "application/octet-stream")
        }
        
        @Test("Respects custom content type")
        func respectsCustomContentType() {
            let body = RequestBody.data(Data(), contentType: "image/png")
            
            #expect(body.contentType == "image/png")
        }
        
        @Test("Handles empty data")
        func handlesEmptyData() throws {
            let body = RequestBody.data(Data())
            
            let encoded = try body.encoded()
            
            #expect(encoded.isEmpty)
        }
    }
    
    // MARK: - JSON Body Tests
    
    @Suite("JSON Body Encoding")
    struct JSONBodyTests {
        
        @Test("Encodes Codable struct to JSON")
        func encodesCodableStruct() throws {
            let user = TestUser(id: 1, name: "Alice", email: "alice@example.com")
            let body = RequestBody.json(user)
            
            let encoded = try body.encoded()
            let decoded = try JSONDecoder().decode(TestUser.self, from: encoded)
            
            #expect(decoded.id == user.id)
            #expect(decoded.name == user.name)
            #expect(decoded.email == user.email)
        }
        
        @Test("Provides JSON content type")
        func providesJSONContentType() {
            let body = RequestBody.json(TestUser(id: 1, name: "Test", email: "test@test.com"))
            
            #expect(body.contentType == "application/json; charset=utf-8")
        }
        
        @Test("Respects custom JSON encoder")
        func respectsCustomEncoder() throws {
            let customEncoder = JSONEncoder()
            customEncoder.dateEncodingStrategy = .iso8601
            customEncoder.outputFormatting = .sortedKeys
            
            let timestamp = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
            let model = CustomEncodableType(timestamp: timestamp, value: "test")
            
            let body = RequestBody.json(model, encoder: customEncoder)
            let encoded = try body.encoded()
            
            // Verify ISO8601 encoding was used
            let jsonString = String(data: encoded, encoding: .utf8)!
            #expect(jsonString.contains("2021-01-01T00:00:00Z"))
        }
        
        @Test("Encodes dictionary")
        func encodesDictionary() throws {
            let dict: [String: String] = ["key": "value", "foo": "bar"]
            let body = RequestBody.json(dict)
            
            let encoded = try body.encoded()
            let decoded = try JSONDecoder().decode([String: String].self, from: encoded)
            
            #expect(decoded == dict)
        }
        
        @Test("Encodes array")
        func encodesArray() throws {
            let array = [1, 2, 3, 4, 5]
            let body = RequestBody.json(array)
            
            let encoded = try body.encoded()
            let decoded = try JSONDecoder().decode([Int].self, from: encoded)
            
            #expect(decoded == array)
        }
    }
    
    // MARK: - Form Body Tests
    
    @Suite("Form Body Encoding")
    struct FormBodyTests {
        
        @Test("Encodes form fields correctly")
        func encodesFormFields() throws {
            let fields = ["username": "alice", "password": "secret"]
            let body = RequestBody.form(fields)
            
            let encoded = try body.encoded()
            let formString = String(data: encoded, encoding: .utf8)!
            
            #expect(formString.contains("username=alice"))
            #expect(formString.contains("password=secret"))
            #expect(formString.contains("&"))
        }
        
        @Test("Provides form content type")
        func providesFormContentType() {
            let body = RequestBody.form(["key": "value"])
            
            #expect(body.contentType == "application/x-www-form-urlencoded")
        }
        
        @Test("Percent-encodes special characters")
        func percentEncodesSpecialCharacters() throws {
            let fields = ["email": "user@example.com", "url": "https://example.com"]
            let body = RequestBody.form(fields)
            
            let encoded = try body.encoded()
            let formString = String(data: encoded, encoding: .utf8)!
            
            // '@' should be encoded as %40
            #expect(formString.contains("user%40example.com"))
            
            // ':' and '/' should be percent-encoded
            #expect(formString.contains("https%3A%2F%2Fexample.com"))
        }
        
        @Test("Encodes all special characters correctly")
        func encodesAllSpecialCharactersCorrectly() throws {
            // Test a comprehensive set of special characters
            let fields = [
                "special": "!*'();:@&=+$,/?#[]",
                "space": "hello world"
            ]
            let body = RequestBody.form(fields)
            
            let encoded = try body.encoded()
            let formString = String(data: encoded, encoding: .utf8)!
            
            // Spaces should be encoded as +
            #expect(formString.contains("hello+world"))
            
            // Special characters should be percent-encoded
            #expect(formString.contains("%21")) // !
            #expect(formString.contains("%40")) // @
            #expect(formString.contains("%3A")) // :
            #expect(formString.contains("%2F")) // /
            #expect(formString.contains("%3D")) // =
        }
        
        @Test("Handles empty form")
        func handlesEmptyForm() throws {
            let body = RequestBody.form([:])
            
            let encoded = try body.encoded()
            
            #expect(encoded.isEmpty)
        }
        
        @Test("Handles spaces in values")
        func handlesSpacesInValues() throws {
            let fields = ["message": "Hello World"]
            let body = RequestBody.form(fields)
            
            let encoded = try body.encoded()
            let formString = String(data: encoded, encoding: .utf8)!
            
            // Space should be encoded as + in application/x-www-form-urlencoded
            #expect(formString.contains("Hello+World"))
        }
        
        @Test("Joins multiple fields with ampersand", arguments: [
            (["a": "1", "b": "2"], 2),
            (["x": "10", "y": "20", "z": "30"], 3)
        ])
        func joinsMultipleFields(fields: [String: String], expectedCount: Int) throws {
            let body = RequestBody.form(fields)
            
            let encoded = try body.encoded()
            let formString = String(data: encoded, encoding: .utf8)!
            
            // Count ampersands (should be count - 1)
            let ampersandCount = formString.filter { $0 == "&" }.count
            #expect(ampersandCount == expectedCount - 1)
        }
    }
    
    // MARK: - Integration Tests
    
    @Suite("RequestBody Integration")
    struct IntegrationTests {
        
        @Test("Request uses body content type automatically")
        func requestUsesBodyContentType() throws {
            let body = RequestBody.json(["key": "value"])
            
            let request = Request(
                method: .post,
                url: URL(string: "https://example.com")!,
                body: body
            )
            
            #expect(request.body != nil)
            #expect(request.body?.contentType == "application/json; charset=utf-8")
        }
        
        @Test("Different body types have correct content types", arguments: [
            (RequestBody.data(Data()), "application/octet-stream"),
            (RequestBody.json(["test": "value"]), "application/json; charset=utf-8"),
            (RequestBody.form(["field": "value"]), "application/x-www-form-urlencoded"),
            (RequestBody.data(Data(), contentType: "text/plain"), "text/plain")
        ])
        func bodyTypesHaveCorrectContentTypes(
            body: RequestBody,
            expectedContentType: String
        ) {
            #expect(body.contentType == expectedContentType)
        }
    }
}
