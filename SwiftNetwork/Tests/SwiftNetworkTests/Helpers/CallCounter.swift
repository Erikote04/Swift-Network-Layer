//
//  CallCounter.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 21/1/26.
//

import Testing
import Foundation

actor CallCounter {
    private(set) var count = 0
    
    func increment() -> Int {
        count += 1
        return count
    }
    
    func reset() {
        count = 0
    }
}
