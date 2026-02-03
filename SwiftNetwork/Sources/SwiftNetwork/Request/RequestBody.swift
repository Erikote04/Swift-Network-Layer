//
//  RequestBody.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 19/1/26.
//

import Foundation

/// Represents the body of an HTTP request.
///
/// `RequestBody` provides a type-safe abstraction over different body formats
/// commonly used in HTTP requests. It handles encoding and Content-Type headers
/// automatically based on the chosen format.
///
/// ## Supported Formats
///
/// - **Raw Data**: Use `.data(_:)` for pre-encoded binary data
/// - **JSON**: Use `.json(_:)` for Swift Codable types that should be JSON-encoded
/// - **Form URL-Encoded**: Use `.form(_:)` for key-value pairs sent as `application/x-www-form-urlencoded`
/// - **Multipart**: Use `.multipart(_:)` for file uploads and mixed content
///
/// ## Example Usage
///
/// ```swift
/// // JSON body
/// struct LoginRequest: Encodable {
///     let username: String
///     let password: String
/// }
///
/// let jsonBody = RequestBody.json(LoginRequest(
///     username: "john@example.com",
///     password: "secret"
/// ))
///
/// // Form body
/// let formBody = RequestBody.form([
///     "username": "john@example.com",
///     "password": "secret"
/// ])
///
/// // Raw data
/// let imageData = Data()
/// let dataBody = RequestBody.data(imageData)
///
/// // Multipart upload
/// let parts = [
///     MultipartFormData(name: "title", value: "My Photo"),
///     MultipartFormData(name: "image", filename: "photo.png", data: imageData, mimeType: "image/png")
/// ]
/// let multipartBody = RequestBody.multipart(parts)
/// ```
///
/// ## Content-Type Headers
///
/// Each body type automatically provides an appropriate Content-Type:
/// - `.data(_:)` → `application/octet-stream` (default, can be overridden)
/// - `.json(_:)` → `application/json; charset=utf-8`
/// - `.form(_:)` → `application/x-www-form-urlencoded`
/// - `.multipart(_:)` → `multipart/form-data; boundary=...`
///
/// - Note: When using `.json(_:)`, encoding errors are deferred until request execution.
///   This allows request construction to succeed even if encoding might fail later.
@frozen
public enum RequestBody: Sendable {
    
    /// Raw binary data with an optional custom Content-Type.
    ///
    /// Use this case when you have pre-encoded data or binary content
    /// such as images, PDFs, or other non-text formats.
    ///
    /// - Parameters:
    ///   - data: The raw data to send in the request body.
    ///   - contentType: The MIME type of the data. Defaults to `application/octet-stream`.
    case data(Data, contentType: String = "application/octet-stream")
    
    /// A JSON-encodable value.
    ///
    /// The provided value will be encoded to JSON using the specified encoder
    /// (or `JSONEncoder()` by default) when the request is executed.
    ///
    /// - Parameters:
    ///   - value: Any `Encodable` value to be JSON-encoded.
    ///   - encoder: The `JSONEncoder` to use. Defaults to a new instance.
    ///
    /// - Note: Encoding happens lazily during request execution. If encoding fails,
    ///   a ``NetworkError/encodingError(_:)`` will be thrown.
    case json(any Encodable & Sendable, encoder: JSONEncoder = JSONEncoder())
    
    /// A form URL-encoded body.
    ///
    /// Encodes the provided dictionary as `application/x-www-form-urlencoded`,
    /// commonly used for HTML form submissions and simple POST requests.
    ///
    /// - Parameter fields: A dictionary of field names and values.
    ///
    /// Example:
    /// ```swift
    /// let body = RequestBody.form([
    ///     "email": "user@example.com",
    ///     "subscribe": "true"
    /// ])
    /// // Encodes to: email=user%40example.com&subscribe=true
    /// ```
    case form([String: String])
    
    /// A multipart/form-data body.
    ///
    /// Used for file uploads and forms that contain mixed content types.
    /// Each part can contain either text data or binary file data.
    ///
    /// The multipart encoding automatically:
    /// - Generates a unique boundary
    /// - Sets the correct Content-Type header
    /// - Formats each part according to RFC 2388
    ///
    /// - Parameter parts: An array of multipart form data parts.
    ///
    /// Example:
    /// ```swift
    /// let imageData = UIImage(named: "photo")!.pngData()!
    /// let parts = [
    ///     MultipartFormData(name: "title", value: "My Photo"),
    ///     MultipartFormData(
    ///         name: "image",
    ///         filename: "photo.png",
    ///         data: imageData,
    ///         mimeType: "image/png"
    ///     )
    /// ]
    /// let body = RequestBody.multipart(parts)
    /// ```
    case multipart([MultipartFormData])
    
    /// Encodes the body into `Data`.
    ///
    /// This method performs the actual encoding based on the body type:
    /// - `.data`: Returns the data as-is
    /// - `.json`: Encodes the value using the provided encoder
    /// - `.form`: Percent-encodes the fields into a query string
    /// - `.multipart`: Encodes parts with boundaries according to RFC 2388
    ///
    /// - Returns: The encoded body data.
    /// - Throws: ``NetworkError/encodingError(_:)`` if encoding fails.
    public func encoded() throws -> Data {
        switch self {
        case .data(let data, _):
            return data
            
        case .json(let value, let encoder):
            do {
                return try encoder.encode(AnyEncodable(value))
            } catch {
                throw NetworkError.encodingError(error)
            }
            
        case .form(let fields):
            let formString = fields
                .map { key, value in
                    let encodedKey = percentEncode(key)
                    let encodedValue = percentEncode(value)
                    return "\(encodedKey)=\(encodedValue)"
                }
                .joined(separator: "&")
            
            guard let data = formString.data(using: .utf8) else {
                throw NetworkError.encodingError(
                    NSError(domain: "RequestBody", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to encode form data as UTF-8"
                    ])
                )
            }
            
            return data
            
        case .multipart(let parts):
            let boundary = MultipartFormData.generateBoundary()
            var body = Data()
            
            // Encode each part
            for part in parts {
                body.append(part.encode(boundary: boundary))
            }
            
            // Final boundary
            if let finalBoundary = "--\(boundary)--\r\n".data(using: .utf8) {
                body.append(finalBoundary)
            }
            
            return body
        }
    }
    
    /// Encodes the body into `Data` and returns the boundary if applicable.
    ///
    /// For multipart bodies, this method returns both the encoded data and the boundary
    /// string used in the encoding. For other body types, the boundary is nil.
    ///
    /// This method is used internally by the transport layer to ensure the same boundary
    /// is used in both the body encoding and the Content-Type header.
    ///
    /// - Returns: A tuple containing the encoded data and an optional boundary string.
    /// - Throws: ``NetworkError/encodingError(_:)`` if encoding fails.
    func encodedWithBoundary() throws -> (data: Data, boundary: String?) {
        switch self {
        case .multipart(let parts):
            let boundary = MultipartFormData.generateBoundary()
            var body = Data()
            
            // Encode each part
            for part in parts {
                body.append(part.encode(boundary: boundary))
            }
            
            // Final boundary
            if let finalBoundary = "--\(boundary)--\r\n".data(using: .utf8) {
                body.append(finalBoundary)
            }
            
            return (body, boundary)
            
        default:
            return (try encoded(), nil)
        }
    }
    
    /// The Content-Type header value for this body.
    ///
    /// Each body type provides an appropriate MIME type:
    /// - `.data`: Returns the custom content type, or `application/octet-stream` by default
    /// - `.json`: Returns `application/json; charset=utf-8`
    /// - `.form`: Returns `application/x-www-form-urlencoded`
    /// - `.multipart`: Returns `multipart/form-data` (the boundary is added by the transport)
    ///
    /// - Note: For multipart bodies, the boundary parameter is added by the transport layer
    ///   when encoding to ensure consistency between the body and Content-Type header.
    public var contentType: String {
        switch self {
        case .data(_, let contentType):
            return contentType
        case .json:
            return "application/json; charset=utf-8"
        case .form:
            return "application/x-www-form-urlencoded"
        case .multipart:
            // The boundary is added by the transport layer during encoding
            return "multipart/form-data"
        }
    }
}

// MARK: - AnyEncodable

/// A type-erased `Encodable` wrapper.
///
/// Internal wrapper that allows `RequestBody.json(_:)` to accept any `Encodable`
/// conforming type while maintaining `Sendable` semantics.
private struct AnyEncodable: Encodable, Sendable {
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

// MARK: - Form Encoding Helpers

/// Percent-encodes a string for use in `application/x-www-form-urlencoded` format.
///
/// Follows the HTML5 specification for form encoding:
/// - Spaces are encoded as `+`
/// - Alphanumeric characters and `-`, `_`, `.`, `~` are not encoded
/// - All other characters are percent-encoded
///
/// - Parameter string: The string to encode.
/// - Returns: The percent-encoded string.
private func percentEncode(_ string: String) -> String {
    // Characters that are allowed in application/x-www-form-urlencoded
    // According to HTML5 spec: alphanumeric, -, _, ., ~
    // Note: We temporarily allow space here and replace it with + later
    var allowed = CharacterSet.alphanumerics
    allowed.insert(charactersIn: "-_.~ ")
    
    // Percent-encode everything else
    guard let encoded = string.addingPercentEncoding(withAllowedCharacters: allowed) else {
        return string
    }
    
    // Replace spaces with + (HTML form encoding convention)
    return encoded.replacingOccurrences(of: " ", with: "+")
}

// MARK: - NetworkError Extension

extension NetworkError {
    
    /// Failed to encode a request body.
    ///
    /// This error is thrown when encoding a ``RequestBody`` fails,
    /// such as when JSON encoding encounters an error or when
    /// form data cannot be converted to UTF-8.
    ///
    /// - Parameter error: The underlying encoding error.
    public static func encodingError(_ error: Error) -> NetworkError {
        .decodingError(error) // Reusing existing case for consistency
    }
}
