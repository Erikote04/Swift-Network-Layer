//
//  NetworkManager.swift
//  SwiftNetworkDemo
//
//  Singleton that configures and provides the NetworkClient
//

import Foundation
import SwiftNetwork

/// Manages network configuration and provides a shared client instance
final class NetworkManager {
    
    // MARK: - Singleton
    static let shared = NetworkManager()
    
    // MARK: - Properties
    
    /// Main network client with standard configuration
    let client: NetworkClient
    
    /// Client configured with custom interceptors for demonstration
    let clientWithInterceptors: NetworkClient
    
    // MARK: - Initialization
    
    private init() {
        // Basic client configuration
        let basicConfig = NetworkClientConfiguration(
            baseURL: URL(string: "https://rickandmortyapi.com/api")!,
            defaultHeaders: [
                "Accept": "application/json",
                "Content-Type": "application/json"
            ],
            timeout: 30.0
        )
        
        self.client = NetworkClient(configuration: basicConfig)
        
        // Advanced client with interceptors
        let advancedConfig = NetworkClientConfiguration(
            baseURL: URL(string: "https://rickandmortyapi.com/api")!,
            defaultHeaders: [
                "Accept": "application/json",
                "Content-Type": "application/json"
            ],
            timeout: 30.0,
            interceptors: [
                // IMPORTANT: Order matters! Interceptors run in sequence.
                
                // 1. Custom headers - Adds app-specific headers FIRST
                CustomHeaderInterceptor(),
                
                // 2. Logging - Now logs the request WITH custom headers
                LoggingInterceptor(level: .headers),
                
                // 3. Retry - Handles transient failures
                RetryInterceptor(maxRetries: 2, delay: 0.5),
                
                // 4. Timeout - Enforces timeout (runs last before transport)
                TimeoutInterceptor(timeout: 30.0)
            ]
        )
        
        self.clientWithInterceptors = NetworkClient(configuration: advancedConfig)
    }
    
    // MARK: - API Methods
    
    /// Fetches a page of characters
    func fetchCharacters(page: Int = 1) async throws -> CharactersResponse {
        let request = Request(
            method: .get,
            url: URL(string: "/character?page=\(page)")!
        )
        
        return try await clientWithInterceptors
            .newCall(request)
            .execute()
    }
    
    /// Fetches a single character by ID
    func fetchCharacter(id: Int) async throws -> Character {
        let request = Request(
            method: .get,
            url: URL(string: "/character/\(id)")!
        )
        
        return try await client
            .newCall(request)
            .execute()
    }
    
    /// Filters characters by name
    func searchCharacters(name: String, page: Int = 1) async throws -> CharactersResponse {
        let request = Request(
            method: .get,
            url: URL(string: "/character?name=\(name)&page=\(page)")!
        )
        
        return try await clientWithInterceptors
            .newCall(request)
            .execute()
    }
}
