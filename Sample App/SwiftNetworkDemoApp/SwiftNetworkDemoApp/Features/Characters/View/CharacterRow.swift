//
//  CharacterRow.swift
//  SwiftNetworkDemo
//
//  Row component for displaying a character in the list
//

import SwiftUI

struct CharacterRow: View {
    
    let character: Character
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile image
            AsyncImage(url: URL(string: character.image)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 60)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                case .failure:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            
            // Character info
            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    // Status indicator
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text("\(character.status.rawValue) - \(character.species)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if !character.type.isEmpty {
                    Text(character.type)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch character.status {
        case .alive:
            return .green
        case .dead:
            return .red
        case .unknown:
            return .gray
        }
    }
}

#Preview("Alive Character") {
    List {
        CharacterRow(character: .preview)
    }
}

#Preview("Dead Character") {
    List {
        CharacterRow(
            character: Character(
                id: 2,
                name: "Toxic Rick",
                status: .dead,
                species: "Humanoid",
                type: "Rick's Toxic Side",
                gender: .male,
                origin: Character.Location(name: "Earth", url: ""),
                location: Character.Location(name: "Earth", url: ""),
                image: "https://rickandmortyapi.com/api/character/avatar/361.jpeg",
                episode: [],
                url: "",
                created: ""
            )
        )
    }
}
