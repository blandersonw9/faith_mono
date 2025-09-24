//
//  ContentView.swift
//  faith
//
//  Created by Blake Anderson on 9/24/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Background Image
            Image("background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
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
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Custom Tab Bar
                CustomTabView(selectedTab: $selectedTab)
            }
        }
    }
}

// MARK: - Custom Tab View
struct CustomTabView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack {
            // Background with image
            Image("background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 75)
                .clipped()
            
            HStack(spacing: 0) {
                // Tab 1: Home
                TabButton(
                    icon: "house.fill",
                    title: "Home",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }
                
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
                
                // Floating Circle Button
                FloatingTabButton(
                    icon: "person.circle.fill"
                ) {
                    // Profile action
                }
            }
            .padding(.horizontal, StyleGuide.spacing.lg)
        }
        .frame(height: 75)
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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(StyleGuide.mainBrown)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                )
                .shadow(color: StyleGuide.shadows.md, radius: 4, x: 0, y: 2)
        }
        .frame(width: 70, height: 70)
        .contentShape(Circle())
        .offset(y: -30) // Raised up a bit more
    }
}

// MARK: - Tab Content Views
struct HomeView: View {
    var body: some View {
        VStack {
            Text("Home")
                .font(StyleGuide.merriweather(size: 24, weight: .bold))
                .foregroundColor(StyleGuide.mainBrown)
            
            Text("Welcome to your Faith journey")
                .font(StyleGuide.merriweather(size: 16))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
        }
    }
}


struct BibleView: View {
    var body: some View {
        VStack {
            Text("Bible")
                .font(StyleGuide.merriweather(size: 24, weight: .bold))
                .foregroundColor(StyleGuide.mainBrown)
            
            Text("Explore God's word with AI assistance")
                .font(StyleGuide.merriweather(size: 16))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}