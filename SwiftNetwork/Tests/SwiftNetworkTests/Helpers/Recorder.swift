//
//  File.swift
//  SwiftNetwork
//
//  Created by Erik Sebastian de Erice Jerez on 7/1/26.
//

import Foundation

actor Recorder {

    private(set) var events: [String] = []

    func record(_ value: String) {
        events.append(value)
    }
}
