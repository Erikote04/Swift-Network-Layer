//
//  SwiftNetworkSampleAppApp.swift
//  SwiftNetworkSampleApp
//
//  Created by Erik Sebastian de Erice Jerez on 3/2/26.
//

import SwiftUI

@main
struct SwiftNetworkSampleAppApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
        }
    }
}
