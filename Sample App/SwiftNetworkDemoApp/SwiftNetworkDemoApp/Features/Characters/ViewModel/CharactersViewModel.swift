//
//  CharactersViewModel.swift
//  SwiftNetworkDemo
//
//  ViewModel for the characters list screen
//

import Foundation
import SwiftNetwork

@Observable
final class CharactersViewModel {
    
    // MARK: - Published State
    
    var characters: [Character] = []
    var isLoading = false
    var errorMessage: String?
    var currentPage = 1
    var hasMorePages = true
    
    // MARK: - Dependencies
    
    private let networkManager: NetworkManager
    
    // MARK: - Initialization
    
    init(networkManager: NetworkManager = .shared) {
        self.networkManager = networkManager
    }
    
    // MARK: - Public Methods
    
    @MainActor
    func fetchCharacters() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await networkManager.fetchCharacters(page: 1)
            
            characters = response.results
            currentPage = 1
            hasMorePages = response.info.next != nil
            
            print("✅ Loaded \(characters.count) characters")
            print("📊 Total characters: \(response.info.count)")
            print("📄 Total pages: \(response.info.pages)")
        } catch let error as NetworkError {
            handleError(error)
        } catch {
            errorMessage = "Unknown error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadMoreCharacters() async {
        guard !isLoading, hasMorePages else { return }
        
        isLoading = true
        
        do {
            let nextPage = currentPage + 1
            let response = try await networkManager.fetchCharacters(page: nextPage)
            
            characters.append(contentsOf: response.results)
            currentPage = nextPage
            hasMorePages = response.info.next != nil
            
            print("✅ Loaded page \(nextPage) - Total: \(characters.count) characters")
        } catch let error as NetworkError {
            handleError(error)
        } catch {
            errorMessage = "Unknown error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    func searchCharacters(query: String) async {
        guard !query.isEmpty else {
            await fetchCharacters()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await networkManager.searchCharacters(name: query)
            
            characters = response.results
            currentPage = 1
            hasMorePages = response.info.next != nil
            
            print("🔍 Found \(characters.count) characters matching '\(query)'")
            
        } catch let error as NetworkError {
            handleError(error)
        } catch {
            errorMessage = "Unknown error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ error: NetworkError) {
        switch error {
        case .cancelled: errorMessage = "Request was cancelled"
        case .invalidResponse: errorMessage = "Invalid response from server"
        case .transportError(let underlyingError): errorMessage = "Network error: \(underlyingError.localizedDescription)"
        case .noData: errorMessage = "No data received from server"
        case .decodingError(let decodingError): errorMessage = "Failed to decode response: \(decodingError.localizedDescription)"
        case .httpError(let statusCode, _):
            switch statusCode {
            case 404: errorMessage = "No characters found"
            case 500...599: errorMessage = "Server error (\(statusCode))"
            default: errorMessage = "HTTP error: \(statusCode)"
            }
        }
        
        print("❌ Error: \(errorMessage ?? "Unknown")")
    }
}
