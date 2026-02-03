//
//  AuthCredentialsTests.swift
//  SwiftNetworkTests
//
//  Created by Erik Sebastian de Erice Jerez on 20/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("AuthCredentials Tests", .tags(.auth))
struct AuthCredentialsTests {
    
    @Test("Credentials are Sendable and Equatable")
    func credentialsAreSendableAndEquatable() {
        let creds1 = AuthCredentials(
            accessToken: "token",
            refreshToken: "refresh",
            expiresIn: 3600,
            provider: .apple
        )
        
        let creds2 = AuthCredentials(
            accessToken: "token",
            refreshToken: "refresh",
            expiresIn: 3600,
            provider: .apple
        )
        
        let creds3 = AuthCredentials(
            accessToken: "different",
            provider: .google
        )
        
        #expect(creds1 == creds2)
        #expect(creds1 != creds3)
    }
    
    @Test("Credentials with different providers are not equal")
    func differentProvidersNotEqual() {
        let apple = AuthCredentials(accessToken: "token", provider: .apple)
        let google = AuthCredentials(accessToken: "token", provider: .google)
        
        #expect(apple != google)
    }
    
    @Test("Credentials can be passed across actor boundaries", arguments: [
        AuthCredentials(accessToken: "test1", provider: .apple),
        AuthCredentials(accessToken: "test2", refreshToken: "refresh", provider: .google),
    ])
    func credentialsAreSendable(credentials: AuthCredentials) async {
        let actor = CredentialsActor()
        await actor.store(credentials)
        let retrieved = await actor.retrieve()
        #expect(retrieved == credentials)
    }
}

// MARK: - Test Actor

private actor CredentialsActor {
    private var credentials: AuthCredentials?
    
    func store(_ creds: AuthCredentials) {
        credentials = creds
    }
    
    func retrieve() -> AuthCredentials? {
        credentials
    }
}
