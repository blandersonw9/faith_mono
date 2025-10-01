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
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authManager.isLoading {
                    LoadingView()
                        .onAppear { print("📱 Showing: LoadingView") }
                        .transition(.opacity)
                } else if authManager.isAuthenticated {
                    if hasCompletedOnboarding {
                        ContentView()
                            .environmentObject(authManager)
                            .environmentObject(bibleNavigator)
                            .onAppear { print("📱 Showing: ContentView") }
                            .transition(.opacity)
                    } else {
                        OnboardingFlowView()
                            .environmentObject(authManager)
                            .environmentObject(bibleNavigator)
                            .onAppear { print("📱 Showing: OnboardingFlowView") }
                            .transition(.opacity)
                    }
                } else {
                    LoginView()
                        .environmentObject(authManager)
                        .environmentObject(bibleNavigator)
                        .onAppear { print("📱 Showing: LoginView") }
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.5), value: authManager.isAuthenticated)
            .animation(.easeInOut(duration: 0.5), value: authManager.isLoading)
            .onChange(of: authManager.isAuthenticated) { newValue in
                print("🔄 isAuthenticated changed to: \(newValue)")
            }
            .onChange(of: authManager.isLoading) { newValue in
                print("🔄 isLoading changed to: \(newValue)")
            }
            .onAppear {
                Config.logConfigStatus()
                
                // TESTING: Comment out after testing onboarding flow
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                
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
