//
//  ContentView.swift
//  SwiftNetworkDemo
//
//  Main content view with tab navigation
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CharactersView()
                .tabItem {
                    Label("Characters", systemImage: "person.3.fill")
                }
            
            TokenDemoView()
                .tabItem {
                    Label("Token Demo", systemImage: "lock.shield.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
