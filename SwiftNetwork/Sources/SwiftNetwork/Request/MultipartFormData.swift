//
//  MultipartFormData.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 19/1/26.
//

import Foundation

/// Represents a single part in a multipart/form-data request.
///
/// `MultipartFormData` encapsulates the data and metadata for a single field
/// or file upload in a multipart form submission. Each part can contain either
/// text data or binary file data with associated metadata.
///
/// Multipart form data is commonly used for file uploads and form submissions
/// that include mixed content types. Each part consists of headers
/// (including Content-Disposition and optionally Content-Type) and body data.
///
/// ## Text Field Example
///
/// ```swift
/// let nameField = MultipartFormData(
///     name: "username",
///     value: "alice"
/// )
/// ```
///
/// ## File Upload Example
///
/// ```swift
/// let imageData = UIImage(named: "profile")!.pngData()!
/// let imageFile = MultipartFormData(
///     name: "avatar",
///     filename: "profile.png",
///     data: imageData,
///     mimeType: "image/png"
/// )
///
/// let request = Request(
///     method: .post,
///     url: uploadURL,
///     body: .multipart([nameField, imageFile])
/// )
/// ```
public struct MultipartFormData: Sendable {
    
    /// The name of the form field.
    ///
    /// This corresponds to the `name` attribute in an HTML form field.
    public let name: String
    
    /// The filename for file uploads.
    ///
    /// When present, this indicates that the part represents a file upload
    /// and will be included in the Content-Disposition header.
    public let filename: String?
    
    /// The data content of this part.
    public let data: Data
    
    /// The MIME type of the data.
    ///
    /// For file uploads, this should match the file's content type
    /// (e.g., "image/png", "application/pdf"). For text fields,
    /// this is typically "text/plain".
    public let mimeType: String
    
    /// Creates a text form field.
    ///
    /// Use this initializer for simple text form fields that don't represent file uploads.
    ///
    /// - Parameters:
    ///   - name: The name of the form field.
    ///   - value: The text value of the field.
    public init(name: String, value: String) {
        self.name = name
        self.filename = nil
        self.data = Data(value.utf8)
        self.mimeType = "text/plain; charset=utf-8"
    }
    
    /// Creates a file upload part.
    ///
    /// Use this initializer for file uploads where you need to specify
    /// both the data and the filename.
    ///
    /// - Parameters:
    ///   - name: The name of the form field.
    ///   - filename: The name of the file being uploaded.
    ///   - data: The file's binary data.
    ///   - mimeType: The MIME type of the file. Defaults to "application/octet-stream".
    public init(
        name: String,
        filename: String,
        data: Data,
        mimeType: String = "application/octet-stream"
    ) {
        self.name = name
        self.filename = filename
        self.data = data
        self.mimeType = mimeType
    }
    
    /// Creates a data part without a filename.
    ///
    /// Use this initializer for binary data that isn't a traditional file upload.
    ///
    /// - Parameters:
    ///   - name: The name of the form field.
    ///   - data: The binary data.
    ///   - mimeType: The MIME type of the data. Defaults to "application/octet-stream".
    public init(
        name: String,
        data: Data,
        mimeType: String = "application/octet-stream"
    ) {
        self.name = name
        self.filename = nil
        self.data = data
        self.mimeType = mimeType
    }
}

// MARK: - Internal Encoding

extension MultipartFormData {
    
    /// Encodes this part into multipart form data format.
    ///
    /// Generates the complete multipart section including boundary, headers,
    /// and body data according to RFC 2388.
    ///
    /// - Parameter boundary: The boundary string used to separate parts.
    /// - Returns: The encoded data for this part, including headers and body.
    func encode(boundary: String) -> Data {
        var result = Data()
        
        // Boundary line
        result.append("--\(boundary)\r\n")
        
        // Content-Disposition header
        var disposition = "Content-Disposition: form-data; name=\"\(name)\""
        if let filename = filename {
            disposition += "; filename=\"\(filename)\""
        }
        result.append("\(disposition)\r\n")
        
        // Content-Type header
        result.append("Content-Type: \(mimeType)\r\n\r\n")
        
        // Body data
        result.append(data)
        result.append("\r\n")
        
        return result
    }
}

// MARK: - Boundary Generation

extension MultipartFormData {
    
    /// Generates a unique boundary string for multipart encoding.
    ///
    /// The boundary is guaranteed to be unique and compliant with RFC 2046.
    /// It uses a UUID to ensure uniqueness across requests.
    ///
    /// - Returns: A boundary string suitable for multipart/form-data encoding.
    static func generateBoundary() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
}

// MARK: - Data Extension

private extension Data {
    
    /// Appends a string to the data using UTF-8 encoding.
    ///
    /// - Parameter string: The string to append.
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
