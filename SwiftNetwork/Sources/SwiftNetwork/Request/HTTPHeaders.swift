//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

public struct HTTPHeaders: Sendable, ExpressibleByDictionaryLiteral {

    private var storage: [String: String]

    public init(_ headers: [String: String] = [:]) {
        self.storage = headers
    }

    public init(dictionaryLiteral elements: (String, String)...) {
        self.storage = Dictionary(uniqueKeysWithValues: elements)
    }

    public subscript(name: String) -> String? {
        get { storage[name] }
        set { storage[name] = newValue }
    }

    public var all: [String: String] {
        storage
    }

    public func merging(_ other: HTTPHeaders) -> HTTPHeaders {
        HTTPHeaders(storage.merging(other.storage) { _, new in new })
    }
}
