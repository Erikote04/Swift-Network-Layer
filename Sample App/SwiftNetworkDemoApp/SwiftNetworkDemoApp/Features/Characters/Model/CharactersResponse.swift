//
//  CharactersResponse.swift
//  SwiftNetworkDemo
//
//  Model for paginated character responses from the API
//

import Foundation

/// Response wrapper for character list with pagination info
struct CharactersResponse: Codable {
    let info: Info
    let results: [Character]
    
    /// Pagination information
    struct Info: Codable {
        let count: Int
        let pages: Int
        let next: String?
        let prev: String?
    }
}
