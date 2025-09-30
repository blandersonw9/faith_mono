//
//  faithApp.swift
//  faith
//
//  Created by Blake Anderson on 9/24/25.
//

import SwiftUI
import UIKit

@main
struct faithApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var bibleNavigator = BibleNavigator()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    LoadingView()
                } else if authManager.isAuthenticated {
                    ContentView()
                        .environmentObject(authManager)
                        .environmentObject(bibleNavigator)
                } else {
                    LoginView()
                        .environmentObject(authManager)
                        .environmentObject(bibleNavigator)
                }
            }
            .onAppear {
                Config.logConfigStatus()
                // Remove UINavigationBar bottom hairline globally and make it transparent
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.shadowColor = .clear
                appearance.backgroundColor = .clear
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                UINavigationBar.appearance().compactAppearance = appearance
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
