//
//  CharactersView.swift
//  SwiftNetworkDemo
//
//  Main view displaying the list of Rick and Morty characters
//

import SwiftUI

struct CharactersView: View {
    
    @State private var viewModel = CharactersViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.characters.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    charactersList
                }
                
                if viewModel.isLoading && viewModel.characters.isEmpty {
                    ProgressView("Loading characters...")
                }
            }
            .navigationTitle("Characters")
            .searchable(text: $searchText, prompt: "Search characters")
            .onChange(of: searchText) { _, newValue in
                Task {
                    await viewModel.searchCharacters(query: newValue)
                }
            }
            .task {
                if viewModel.characters.isEmpty {
                    await viewModel.fetchCharacters()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var charactersList: some View {
        List {
            ForEach(viewModel.characters) { character in
                CharacterRow(character: character)
            }
            
            if viewModel.isLoading && !viewModel.characters.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Characters", systemImage: "person.3.slash")
        } description: {
            if searchText.isEmpty {
                Text("Pull to refresh")
            } else {
                Text("No characters found for '\(searchText)'")
            }
        }
    }
}

#Preview {
    CharactersView()
}
