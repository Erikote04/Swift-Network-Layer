//
//  Character.swift
//  SwiftNetworkDemo
//
//  Model representing a Rick and Morty character from the API
//

import Foundation

/// Represents a character from the Rick and Morty API
struct Character: Codable, Identifiable {
    let id: Int
    let name: String
    let status: Status
    let species: String
    let type: String
    let gender: Gender
    let origin: Location
    let location: Location
    let image: String
    let episode: [String]
    let url: String
    let created: String
    
    /// Character status: Alive, Dead, or Unknown
    enum Status: String, Codable {
        case alive = "Alive"
        case dead = "Dead"
        case unknown = "unknown"
    }
    
    /// Character gender
    enum Gender: String, Codable {
        case female = "Female"
        case male = "Male"
        case genderless = "Genderless"
        case unknown = "unknown"
    }
    
    /// Location reference with name and URL
    struct Location: Codable {
        let name: String
        let url: String
    }
}

// MARK: - Preview Helpers
extension Character {
    static var preview: Character {
        Character(
            id: 1,
            name: "Rick Sanchez",
            status: .alive,
            species: "Human",
            type: "",
            gender: .male,
            origin: Location(
                name: "Earth (C-137)",
                url: "https://rickandmortyapi.com/api/location/1"
            ),
            location: Location(
                name: "Earth (Replacement Dimension)",
                url: "https://rickandmortyapi.com/api/location/20"
            ),
            image: "https://rickandmortyapi.com/api/character/avatar/1.jpeg",
            episode: ["https://rickandmortyapi.com/api/episode/1"],
            url: "https://rickandmortyapi.com/api/character/1",
            created: "2017-11-04T18:48:46.250Z"
        )
    }
    
    static var previewList: [Character] {
        [
            preview,
            Character(
                id: 2,
                name: "Morty Smith",
                status: .alive,
                species: "Human",
                type: "",
                gender: .male,
                origin: Location(name: "Earth", url: ""),
                location: Location(name: "Earth", url: ""),
                image: "https://rickandmortyapi.com/api/character/avatar/2.jpeg",
                episode: [],
                url: "",
                created: ""
            )
        ]
    }
}
