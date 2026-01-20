//
//  KeychainTokenStore.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Foundation
import Security

/// A secure token store that persists tokens in the system keychain.
///
/// `KeychainTokenStore` provides secure, persistent storage for authentication
/// tokens using the iOS/macOS Keychain Services API.
public actor KeychainTokenStore: TokenStore {
    
    private let service: String
    private let account: String
    
    /// Creates a new keychain token store.
    ///
    /// - Parameters:
    ///   - service: The service identifier for keychain items (typically your app's bundle ID).
    ///   - account: The account name for the token (e.g., "auth_token").
    public init(service: String, account: String = "access_token") {
        self.service = service
        self.account = account
    }
    
    /// Returns the currently stored token from the keychain.
    ///
    /// - Returns: The current token, or `nil` if none is stored.
    public func currentToken() async -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    /// Updates the stored token in the keychain.
    ///
    /// If a token already exists, it is replaced. If the token is empty,
    /// the stored token is deleted.
    ///
    /// - Parameter newToken: The new token to store.
    public func updateToken(_ newToken: String) async {
        guard !newToken.isEmpty else {
            await deleteToken()
            return
        }
        
        guard let tokenData = newToken.data(using: .utf8) else {
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: tokenData
        ]
        
        // Try to update first
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        if updateStatus == errSecItemNotFound {
            // Item doesn't exist, add it
            var addQuery = query
            addQuery[kSecValueData as String] = tokenData
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }
    
    /// Deletes the stored token from the keychain.
    public func deleteToken() async {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
