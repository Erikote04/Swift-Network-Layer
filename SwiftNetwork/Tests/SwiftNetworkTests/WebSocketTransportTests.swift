//
//  WebSocketTransportTests.swift
//  SwiftNetworkTests
//
//  Created by Erik Sebastian de Erice Jerez on 29/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("WebSocket Transport", .tags(.websocket))
struct WebSocketTransportTests {
    
    // MARK: - Message Tests
    
    @Test("WebSocketMessage text data conversion")
    func textMessageDataConversion() {
        let message = WebSocketMessage.text("Hello, WebSocket!")
        let data = message.data
        let reconstructed = String(data: data, encoding: .utf8)
        
        #expect(reconstructed == "Hello, WebSocket!")
        #expect(message.isText)
        #expect(!message.isBinary)
    }
    
    @Test("WebSocketMessage binary data conversion")
    func binaryMessageDataConversion() {
        let originalData = Data([0x01, 0x02, 0x03, 0x04])
        let message = WebSocketMessage.binary(originalData)
        
        #expect(message.data == originalData)
        #expect(!message.isText)
        #expect(message.isBinary)
    }
    
    @Test("WebSocketMessage string property")
    func messageStringProperty() {
        let textMessage = WebSocketMessage.text("Test")
        #expect(textMessage.string == "Test")
        
        let utf8Data = "Hello".data(using: .utf8)!
        let binaryMessage = WebSocketMessage.binary(utf8Data)
        #expect(binaryMessage.string == "Hello")
        
        let invalidData = Data([0xFF, 0xFE])
        let invalidMessage = WebSocketMessage.binary(invalidData)
        #expect(invalidMessage.string == nil)
    }
    
    @Test("WebSocketMessage equatable conformance")
    func messageEquatability() {
        let text1 = WebSocketMessage.text("Hello")
        let text2 = WebSocketMessage.text("Hello")
        let text3 = WebSocketMessage.text("World")
        
        #expect(text1 == text2)
        #expect(text1 != text3)
        
        let data = Data([0x01, 0x02])
        let binary1 = WebSocketMessage.binary(data)
        let binary2 = WebSocketMessage.binary(data)
        
        #expect(binary1 == binary2)
        #expect(text1 != binary1)
    }
    
    // MARK: - Error Tests
    
    @Test("WebSocketError localized descriptions")
    func errorLocalizedDescriptions() {
        let errors: [WebSocketError] = [
            .connectionFailed("Network unavailable"),
            .connectionClosed(code: 1000, reason: "User closed"),
            .alreadyClosed,
            .cancelled,
            .sendFailed("Send error"),
            .receiveFailed("Receive error"),
            .invalidMessage,
            .transportError("Transport error")
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
    
    @Test("WebSocketError equatable conformance")
    func errorEquatability() {
        let error1 = WebSocketError.connectionFailed("Test")
        let error2 = WebSocketError.connectionFailed("Test")
        let error3 = WebSocketError.alreadyClosed
        
        #expect(error1 == error2)
        #expect(error1 != error3)
        
        let close1 = WebSocketError.connectionClosed(code: 1000, reason: "Normal")
        let close2 = WebSocketError.connectionClosed(code: 1000, reason: "Normal")
        let close3 = WebSocketError.connectionClosed(code: 1001, reason: "Going away")
        
        #expect(close1 == close2)
        #expect(close1 != close3)
    }
    
    @Test("WebSocketError different types not equal")
    func errorDifferentTypesNotEqual() {
        let error1 = WebSocketError.cancelled
        let error2 = WebSocketError.alreadyClosed
        let error3 = WebSocketError.invalidMessage
        
        #expect(error1 != error2)
        #expect(error2 != error3)
        #expect(error1 != error3)
    }
    
    @Test("WebSocketError with same description equal")
    func errorSameDescriptionEqual() {
        let send1 = WebSocketError.sendFailed("Network error")
        let send2 = WebSocketError.sendFailed("Network error")
        let send3 = WebSocketError.sendFailed("Different error")
        
        #expect(send1 == send2)
        #expect(send1 != send3)
        
        let recv1 = WebSocketError.receiveFailed("Timeout")
        let recv2 = WebSocketError.receiveFailed("Timeout")
        
        #expect(recv1 == recv2)
    }
}
