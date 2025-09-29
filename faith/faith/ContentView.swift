//
//  ContentView.swift
//  faith
//
//  Created by Blake Anderson on 9/24/25.
//

import SwiftUI
import Supabase

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var bibleNavigator: BibleNavigator
    @State private var selectedTab = 0
    @State private var showingChat = false
    @State private var initialChatPrompt: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
            // Conditional background based on selected tab
            if selectedTab == 0 {
                Image("background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea(.all)
                
            } else {
                Image("backgroundBeige")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea(.all)
            }
            
            
            VStack(spacing: 0) {
                // Main Content Area
                TabView(selection: $selectedTab) {
                    // Tab 1: Home
                    HomeView()
                        .tag(0)
                    
                    // Tab 2: Bible
                    BibleView()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .gesture(DragGesture().onChanged { _ in })
                
                // Custom Tab Bar
                CustomTabView(selectedTab: $selectedTab, showingChat: $showingChat)
            }
            }
            .navigationDestination(isPresented: $showingChat) {
                ChatView(showingChat: $showingChat, selectedTab: $selectedTab, initialPrompt: initialChatPrompt)
                    .navigationBarHidden(true)
            }
        }
        .onChange(of: bibleNavigator.pendingSelection) { sel in
            guard sel != nil else { return }
            selectedTab = 1
            showingChat = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .openChatWithPrompt)) { note in
            if let prompt = note.object as? String {
                initialChatPrompt = prompt
                showingChat = true
            }
        }
    }
}

// MARK: - Custom Tab View
struct CustomTabView: View {
    @Binding var selectedTab: Int
    @Binding var showingChat: Bool
    
    var body: some View {
        ZStack {
            // Background with beige color
            StyleGuide.backgroundBeige
                .frame(height: 85)
            
            HStack(spacing: 0) {
                Spacer()

                TabButton(
                    icon: "house.fill",
                    title: "Home",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }
                
                Spacer()

                Spacer()
                
                // Tab 2: Bible
                TabButton(
                    icon: "book.fill",
                    title: "Bible",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }
                
                Spacer()
                Spacer()
                
                // Floating Circle Button
                FloatingTabButton(
                    icon: "aiIcon",
                    isSystemIcon: false
                ) {
                    showingChat = true
                }
            }
            .padding(.horizontal, StyleGuide.spacing.lg)
        }
        .frame(height: 85)
        .shadow(color: StyleGuide.mainBrown.opacity(0.25), radius: 4, x: 0, y: 0)
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isSelected ? StyleGuide.mainBrown : StyleGuide.mainBrown.opacity(0.5))
                .frame(width: 80, height: 75, alignment: .top)
                .padding(.top, 16)
        }
        .frame(width: 80, height: 75)
        .contentShape(Rectangle())
    }
}

// MARK: - Floating Tab Button
struct FloatingTabButton: View {
    let icon: String
    let isSystemIcon: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(StyleGuide.mainBrown)
                .frame(width: 60, height: 60)
                .overlay(
                    Image("cross")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                    // Group {
                    //     if isSystemIcon {
                    //         Image(systemName: icon)
                    //             .font(.system(size: 32, weight: .semibold))
                    //             .foregroundColor(.white)
                    //     } else {
                    //         Image(icon)
                    //             .renderingMode(.template)
                    //             .resizable()
                    //             .aspectRatio(contentMode: .fit)
                    //             .frame(width: 36, height: 36)
                    //             .foregroundColor(.white)
                    //     }
                    // }
                )
                .shadow(color: StyleGuide.shadows.md, radius: 4, x: 0, y: 2)
        }
        .frame(width: 60, height: 60)
        .contentShape(Circle())
        .offset(y: -30) // Center of circle aligned with top of tab bar
    }
}




#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
