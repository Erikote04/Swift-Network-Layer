//
//  AnyEncodableWrapper.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 28/1/26.
//

import Foundation

/// A type-erased wrapper for any `Encodable & Sendable` value.
///
/// Used internally for hashing JSON request bodies.
struct AnyEncodableWrapper: Encodable, Sendable {
    private let _encode: @Sendable (Encoder) throws -> Void
    
    init(_ encodable: any Encodable & Sendable) {
        self._encode = { encoder in
            try encodable.encode(to: encoder)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
