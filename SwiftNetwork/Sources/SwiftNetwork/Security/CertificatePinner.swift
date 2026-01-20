//
//  CertificatePinner.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 20/1/26.
//

import Foundation
import CommonCrypto

/// Validates server certificates against pinned certificates or public keys.
///
/// `CertificatePinner` provides certificate pinning to prevent man-in-the-middle
/// attacks by ensuring that the server's certificate matches a known, trusted
/// certificate or public key.
///
/// ## Pinning Strategies
///
/// Certificate pinning supports two main strategies:
///
/// - **Certificate Pinning**: Pins the entire certificate (leaf or intermediate)
/// - **Public Key Pinning**: Pins only the public key (more flexible for certificate rotation)
///
/// ## Example Usage
///
/// ```swift
/// // Create a pinner with public key hashes
/// let pinner = CertificatePinner(
///     pins: [
///         "api.example.com": [
///             .publicKeyHash("sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="),
///             .publicKeyHash("sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=")
///         ]
///     ]
/// )
///
/// // Use with network client configuration
/// let config = NetworkClientConfiguration(
///     certificatePinner: pinner
/// )
/// ```
///
/// ## Security Considerations
///
/// - Always pin at least two certificates/keys (primary + backup)
/// - Use public key pinning for easier certificate rotation
/// - Test thoroughly before deploying to production
/// - Have a backup plan for pin updates
public struct CertificatePinner: Sendable {
    
    /// A pinned certificate or public key for a specific host.
    public enum Pin: Sendable, Hashable {
        
        /// Pins the SHA-256 hash of the certificate's public key.
        ///
        /// Format: `"sha256/BASE64_ENCODED_HASH"`
        ///
        /// This is the recommended approach as it survives certificate renewal
        /// as long as the public key remains the same.
        case publicKeyHash(String)
        
        /// Pins the SHA-256 hash of the entire certificate.
        ///
        /// Format: `"sha256/BASE64_ENCODED_HASH"`
        ///
        /// This requires updating pins when certificates are renewed.
        case certificateHash(String)
    }
    
    /// The pinning policy to apply when validation occurs.
    public enum Policy: Sendable {
        
        /// Validates that at least one pin matches.
        ///
        /// This is the recommended policy for most use cases.
        case any
        
        /// Validates that all certificates in the chain match a pin.
        ///
        /// This provides maximum security but requires careful management.
        case all
    }
    
    private let pins: [String: Set<Pin>]
    private let policy: Policy
    
    /// Creates a certificate pinner with host-specific pins.
    ///
    /// - Parameters:
    ///   - pins: A dictionary mapping hostnames to their pinned certificates/keys.
    ///   - policy: The validation policy to apply. Defaults to `.any`.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let pinner = CertificatePinner(
    ///     pins: [
    ///         "api.example.com": [
    ///             .publicKeyHash("sha256/primaryKeyHash..."),
    ///             .publicKeyHash("sha256/backupKeyHash...")
    ///         ],
    ///         "cdn.example.com": [
    ///             .publicKeyHash("sha256/cdnKeyHash...")
    ///         ]
    ///     ]
    /// )
    /// ```
    public init(
        pins: [String: Set<Pin>],
        policy: Policy = .any
    ) {
        self.pins = pins
        self.policy = policy
    }
    
    /// Validates a server trust challenge against pinned certificates.
    ///
    /// This method is called by `URLSessionDelegate` when a server requests
    /// authentication via TLS/SSL.
    ///
    /// - Parameters:
    ///   - challenge: The authentication challenge from URLSession.
    ///   - host: The hostname being validated.
    /// - Returns: `true` if the certificate chain matches the pins, `false` otherwise.
    public func validate(
        challenge: URLAuthenticationChallenge,
        for host: String
    ) -> Bool {
        // Check if we have pins for this host
        guard let expectedPins = pins[host], !expectedPins.isEmpty else {
            // No pins configured for this host - allow by default
            return true
        }
        
        // Get the server trust from the challenge
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            return false
        }
        
        // Validate the trust
        return validate(serverTrust: serverTrust, for: host, expectedPins: expectedPins)
    }
    
    /// Validates a server trust against expected pins.
    ///
    /// - Parameters:
    ///   - serverTrust: The server trust to validate.
    ///   - host: The hostname being validated.
    ///   - expectedPins: The set of expected pins for this host.
    /// - Returns: `true` if validation succeeds, `false` otherwise.
    private func validate(
        serverTrust: SecTrust,
        for host: String,
        expectedPins: Set<Pin>
    ) -> Bool {
        // Set validation policy
        let policy = SecPolicyCreateSSL(true, host as CFString)
        SecTrustSetPolicies(serverTrust, policy)
        
        // Evaluate the trust
        var error: CFError?
        guard SecTrustEvaluateWithError(serverTrust, &error) else {
            return false
        }
        
        // Get certificate chain
        guard let certificateChain = getCertificateChain(from: serverTrust) else {
            return false
        }
        
        // Extract actual pins from the chain
        let actualPins = extractPins(from: certificateChain)
        
        // Validate according to policy
        switch self.policy {
        case .any:
            // At least one pin must match
            return !actualPins.isDisjoint(with: expectedPins)
            
        case .all:
            // All certificates in chain must have matching pins
            return certificateChain.allSatisfy { certificate in
                let certPins = extractPins(from: [certificate])
                return !certPins.isDisjoint(with: expectedPins)
            }
        }
    }
    
    /// Extracts the certificate chain from a server trust.
    ///
    /// - Parameter serverTrust: The server trust to extract from.
    /// - Returns: An array of certificates, or `nil` if extraction fails.
    private func getCertificateChain(from serverTrust: SecTrust) -> [SecCertificate]? {
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        guard certificateCount > 0 else { return nil }
        
        var certificates: [SecCertificate] = []
        
        for index in 0..<certificateCount {
            if let certificate = SecTrustGetCertificateAtIndex(serverTrust, index) {
                certificates.append(certificate)
            }
        }
        
        return certificates.isEmpty ? nil : certificates
    }
    
    /// Extracts pins from a certificate chain.
    ///
    /// - Parameter certificates: The certificates to extract pins from.
    /// - Returns: A set of pins found in the certificates.
    private func extractPins(from certificates: [SecCertificate]) -> Set<Pin> {
        var pins = Set<Pin>()
        
        for certificate in certificates {
            // Extract public key hash
            if let publicKeyHash = extractPublicKeyHash(from: certificate) {
                pins.insert(.publicKeyHash(publicKeyHash))
            }
            
            // Extract certificate hash
            if let certificateHash = extractCertificateHash(from: certificate) {
                pins.insert(.certificateHash(certificateHash))
            }
        }
        
        return pins
    }
    
    /// Extracts the SHA-256 hash of a certificate's public key.
    ///
    /// - Parameter certificate: The certificate to extract from.
    /// - Returns: The base64-encoded hash, or `nil` if extraction fails.
    private func extractPublicKeyHash(from certificate: SecCertificate) -> String? {
        guard let publicKey = SecCertificateCopyKey(certificate),
              let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            return nil
        }
        
        let hash = sha256(data: publicKeyData)
        return "sha256/\(hash.base64EncodedString())"
    }
    
    /// Extracts the SHA-256 hash of the entire certificate.
    ///
    /// - Parameter certificate: The certificate to hash.
    /// - Returns: The base64-encoded hash, or `nil` if extraction fails.
    private func extractCertificateHash(from certificate: SecCertificate) -> String? {
        let certificateData = SecCertificateCopyData(certificate) as Data
        let hash = sha256(data: certificateData)
        return "sha256/\(hash.base64EncodedString())"
    }
    
    /// Computes the SHA-256 hash of data.
    ///
    /// - Parameter data: The data to hash.
    /// - Returns: The hash as Data.
    private func sha256(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}
