//
//  ContentView.swift
//  SwiftNetworkSampleApp
//
//  Created by Erik Sebastian de Erice Jerez on 3/2/26.
//

import SwiftUI

struct ContentView: View {
    @Bindable var appState: AppState

    var body: some View {
        NavigationStack {
            FeatureListView(client: appState.client)
        }
    }
}

#Preview {
    ContentView(appState: AppState())
}
