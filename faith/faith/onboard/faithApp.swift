//
//  faithApp.swift
//  faith
//
//  Created by Blake Anderson on 9/24/25.
//

import SwiftUI

@main
struct faithApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                        .environmentObject(authManager)
                } else {
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .onAppear {
                Config.logConfigStatus()
            }
        }
    }
}
