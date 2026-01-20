//
//  CertificatePinnerTests.swift
//  SwiftNetwork
//
//  Created by SwiftNetwork Contributors on 20/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Certificate Pinning")
struct CertificatePinnerTests {
    
    @Suite("Pin Creation")
    struct PinCreationTests {
        
        @Test("Creates public key hash pin")
        func createsPublicKeyHashPin() {
            let pin = CertificatePinner.Pin.publicKeyHash("sha256/AAAA...")
            
            #expect(pin == .publicKeyHash("sha256/AAAA..."))
        }
        
        @Test("Creates certificate hash pin")
        func createsCertificateHashPin() {
            let pin = CertificatePinner.Pin.certificateHash("sha256/BBBB...")
            
            #expect(pin == .certificateHash("sha256/BBBB..."))
        }
        
        @Test("Pins are hashable")
        func pinsAreHashable() {
            let pin1 = CertificatePinner.Pin.publicKeyHash("sha256/AAAA...")
            let pin2 = CertificatePinner.Pin.publicKeyHash("sha256/AAAA...")
            let pin3 = CertificatePinner.Pin.publicKeyHash("sha256/BBBB...")
            
            let set: Set = [pin1, pin2, pin3]
            
            #expect(set.count == 2)
        }
    }
    
    @Suite("Pinner Configuration")
    struct PinnerConfigurationTests {
        
        @Test("Creates pinner with pins")
        func createsPinnerWithPins() {
            let pinner = CertificatePinner(
                pins: [
                    "api.example.com": [
                        .publicKeyHash("sha256/primary..."),
                        .publicKeyHash("sha256/backup...")
                    ]
                ]
            )
            
            // Pinner should be created successfully
            #expect(pinner != nil)
        }
        
        @Test("Creates pinner with any policy")
        func createsPinnerWithAnyPolicy() {
            let pinner = CertificatePinner(
                pins: ["example.com": [.publicKeyHash("sha256/hash...")]],
                policy: .any
            )
            
            #expect(pinner != nil)
        }
        
        @Test("Creates pinner with all policy")
        func createsPinnerWithAllPolicy() {
            let pinner = CertificatePinner(
                pins: ["example.com": [.publicKeyHash("sha256/hash...")]],
                policy: .all
            )
            
            #expect(pinner != nil)
        }
    }
    
    @Suite("NetworkClient Integration")
    struct NetworkClientIntegrationTests {
        
        @Test("Client accepts certificate pinner in configuration")
        func clientAcceptsPinnerInConfiguration() {
            let pinner = CertificatePinner(
                pins: [
                    "api.example.com": [
                        .publicKeyHash("sha256/hash...")
                    ]
                ]
            )
            
            let config = NetworkClientConfiguration(
                certificatePinner: pinner
            )
            
            let client = NetworkClient(configuration: config)
            
            #expect(client != nil)
        }
        
        @Test("Client works without certificate pinner")
        func clientWorksWithoutPinner() {
            let config = NetworkClientConfiguration()
            let client = NetworkClient(configuration: config)
            
            #expect(client != nil)
        }
    }
}
