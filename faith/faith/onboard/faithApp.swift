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
    @StateObject private var authManager: AuthManager
    @StateObject private var bibleNavigator: BibleNavigator
    @StateObject private var userDataManager: UserDataManager
    @StateObject private var dailyLessonManager: DailyLessonManager
    @StateObject private var customStudyManager: CustomStudyManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    init() {
        // Create a single instance of AuthManager and reuse it
        let auth = AuthManager()
        _authManager = StateObject(wrappedValue: auth)
        _bibleNavigator = StateObject(wrappedValue: BibleNavigator())
        _userDataManager = StateObject(wrappedValue: UserDataManager(supabase: auth.supabase, authManager: auth))
        _dailyLessonManager = StateObject(wrappedValue: DailyLessonManager(supabase: auth.supabase))
        _customStudyManager = StateObject(wrappedValue: CustomStudyManager(supabaseClient: auth.supabase))
    }
    
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
                            .environmentObject(userDataManager)
                            .environmentObject(dailyLessonManager)
                            .environmentObject(customStudyManager)
                            .task {
                                print("📱 Showing: ContentView - Loading user data")
                                // Fetch user data when authenticated
                                await userDataManager.fetchUserData()
                            }
                            .transition(.opacity)
                    } else {
                        OnboardingFlowView()
                            .environmentObject(authManager)
                            .environmentObject(bibleNavigator)
                            .environmentObject(userDataManager)
                            .environmentObject(dailyLessonManager)
                            .environmentObject(customStudyManager)
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
