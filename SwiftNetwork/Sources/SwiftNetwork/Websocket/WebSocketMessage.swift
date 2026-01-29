//
//  WebSocketMessage.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 29/1/26.
//

import Foundation

/// Represents a message sent or received over a WebSocket connection.
///
/// `WebSocketMessage` supports both text and binary data formats,
/// corresponding to the WebSocket protocol's text and binary frames.
public enum WebSocketMessage: Sendable, Equatable {
    
    /// A text message containing a UTF-8 encoded string.
    case text(String)
    
    /// A binary message containing raw data.
    case binary(Data)
    
    /// Returns the message content as `Data`.
    ///
    /// - For text messages: returns UTF-8 encoded data
    /// - For binary messages: returns the data directly
    public var data: Data {
        switch self {
        case .text(let string):
            return Data(string.utf8)
        case .binary(let data):
            return data
        }
    }
    
    /// Returns the message content as a `String` if possible.
    ///
    /// - For text messages: returns the string directly
    /// - For binary messages: attempts UTF-8 decoding
    ///
    /// - Returns: The message as a string, or `nil` if binary data
    ///   cannot be decoded as UTF-8.
    public var string: String? {
        switch self {
        case .text(let string):
            return string
        case .binary(let data):
            return String(data: data, encoding: .utf8)
        }
    }
    
    /// Indicates whether this is a text message.
    public var isText: Bool {
        if case .text = self { return true }
        return false
    }
    
    /// Indicates whether this is a binary message.
    public var isBinary: Bool {
        if case .binary = self { return true }
        return false
    }
}
