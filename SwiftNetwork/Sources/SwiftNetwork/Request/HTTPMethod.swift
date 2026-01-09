//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 18/12/25.
//

import Foundation

/// Represents an HTTP request method.
///
/// This enum defines the standard HTTP methods supported by SwiftNetwork.
public enum HTTPMethod: String, Sendable {

    /// HTTP GET method.
    case get     = "GET"

    /// HTTP POST method.
    case post    = "POST"

    /// HTTP PUT method.
    case put     = "PUT"

    /// HTTP PATCH method.
    case patch   = "PATCH"

    /// HTTP DELETE method.
    case delete  = "DELETE"

    /// HTTP HEAD method.
    case head    = "HEAD"

    /// HTTP OPTIONS method.
    case options = "OPTIONS"
}
