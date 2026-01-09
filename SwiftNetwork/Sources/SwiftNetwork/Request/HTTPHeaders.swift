//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// A type-safe representation of HTTP headers.
///
/// `HTTPHeaders` wraps a dictionary of header names and values,
/// providing convenience APIs for merging and mutation while
/// remaining Sendable and value-based.
public struct HTTPHeaders: Sendable, ExpressibleByDictionaryLiteral {

    private var storage: [String: String]

    /// Creates a new collection of HTTP headers.
    ///
    /// - Parameter headers: A dictionary of header names and values.
    public init(_ headers: [String: String] = [:]) {
        self.storage = headers
    }

    /// Creates HTTP headers from a dictionary literal.
    ///
    /// - Parameter elements: Header name and value pairs.
    public init(dictionaryLiteral elements: (String, String)...) {
        self.storage = Dictionary(uniqueKeysWithValues: elements)
    }

    /// Accesses or modifies the value of a header.
    ///
    /// - Parameter name: The name of the header.
    public subscript(name: String) -> String? {
        get { storage[name] }
        set { storage[name] = newValue }
    }

    /// Returns all headers as a dictionary.
    public var all: [String: String] {
        storage
    }

    /// Merges the current headers with another collection.
    ///
    /// Values from the other collection take precedence.
    ///
    /// - Parameter other: The headers to merge.
    /// - Returns: A new `HTTPHeaders` instance containing the merged values.
    public func merging(_ other: HTTPHeaders) -> HTTPHeaders {
        HTTPHeaders(storage.merging(other.storage) { _, new in new })
    }
}
