//
//  String+Encryption.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Foundation
import CommonCrypto

extension String {
    
    /// Computes the SHA-256 hash of the string.
    func sha256Hash() -> String {
        guard let data = data(using: .utf8) else {
            return self
        }
        
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
