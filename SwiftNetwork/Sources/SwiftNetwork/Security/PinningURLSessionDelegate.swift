//
//  PinningURLSessionDelegate.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 20/1/26.
//

import Foundation

/// A URLSession delegate that performs certificate pinning.
///
/// `PinningURLSessionDelegate` integrates certificate pinning into the
/// URLSession authentication flow, validating server certificates against
/// configured pins.
///
/// Delegate used internally by `URLSessionTransport` when certificate pinning is enabled.
final class PinningURLSessionDelegate: NSObject, URLSessionDelegate {
    
    private let pinner: CertificatePinner
    
    /// Creates a new pinning delegate.
    ///
    /// - Parameter pinner: The certificate pinner to use for validation.
    init(pinner: CertificatePinner) {
        self.pinner = pinner
    }
    
    /// Handles server trust authentication challenges.
    ///
    /// - Parameters:
    ///   - session: The URLSession requesting authentication.
    ///   - challenge: The authentication challenge.
    ///   - completionHandler: The completion handler to call with the result.
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Only handle server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Get the host
        let host = challenge.protectionSpace.host
        
        // Validate with pinner
        if pinner.validate(challenge: challenge, for: host) {
            // Pinning succeeded - create credential
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        } else {
            // Pinning failed - cancel
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
