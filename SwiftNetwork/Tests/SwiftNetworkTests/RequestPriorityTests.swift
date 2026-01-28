//
//  RequestPriorityTests.swift
//  SwiftNetworkTests
//
//  Created by Erik Sebastian de Erice Jerez on 28/1/26.
//

import Testing
import Foundation
@testable import SwiftNetwork

@Suite("Request Priority Tests")
struct RequestPriorityTests {
    
    @Test("Priority levels are ordered correctly")
    func priorityOrdering() {
        #expect(RequestPriority.background < .low)
        #expect(RequestPriority.low < .normal)
        #expect(RequestPriority.normal < .high)
        #expect(RequestPriority.high < .critical)
    }
    
    @Test("Priority maps to correct task priority values")
    func taskPriorityMapping() {
        #expect(RequestPriority.background.taskPriority == 0.0)
        #expect(RequestPriority.low.taskPriority == 0.25)
        #expect(RequestPriority.normal.taskPriority == 0.5)
        #expect(RequestPriority.high.taskPriority == 0.75)
        #expect(RequestPriority.critical.taskPriority == 1.0)
    }
    
    @Test("Priority maps to correct Swift task priority")
    func swiftTaskPriorityMapping() {
        #expect(RequestPriority.background.swiftTaskPriority == .background)
        #expect(RequestPriority.low.swiftTaskPriority == .low)
        #expect(RequestPriority.normal.swiftTaskPriority == .medium)
        #expect(RequestPriority.high.swiftTaskPriority == .high)
        #expect(RequestPriority.critical.swiftTaskPriority == .userInitiated)
    }
    
    @Test("Request defaults to normal priority")
    func defaultPriority() {
        let request = Request(
            method: .get,
            url: URL(string: "https://api.example.com/data")!
        )
        
        #expect(request.priority == .normal)
    }
    
    @Test("Request accepts custom priority")
    func customPriority() {
        let request = Request(
            method: .get,
            url: URL(string: "https://api.example.com/data")!,
            priority: .high
        )
        
        #expect(request.priority == .high)
    }
}
