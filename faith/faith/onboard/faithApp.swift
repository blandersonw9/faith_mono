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
                if authManager.isLoading {
                    LoadingView()
                } else if authManager.isAuthenticated {
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

// MARK: - Loading View
struct LoadingView: View {
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            // Main app background
            Image("background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea(.all)
            
            // App Icon
            Image("crossFill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .cornerRadius(20)
        }
        .opacity(opacity)
        .onAppear {
            // Ensure minimum 0.5 second display with slow fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.8)) {
                    opacity = 0.0
                }
            }
        }
    }
}
