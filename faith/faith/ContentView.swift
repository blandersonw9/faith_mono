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
    // Mirror BibleView's reading mode so we can color the parent background
    @State private var bibleReadingMode: ReadingMode = {
        if let saved = UserDefaults.standard.string(forKey: "bibleReadingMode"),
           let mode = ReadingMode(rawValue: saved) {
            return mode
        }
        return .day
    }()
    // Bottom safe-area inset (for painting under the home indicator)
    private var bottomSafeInset: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.bottom
        }
        return 0
    }
    
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
                // Match Bible reading mode background to fill the top area behind the status bar
                bibleReadingMode.backgroundColor
                    .ignoresSafeArea(.all)
            }
            
            
            // Main Content Area
            TabView(selection: $selectedTab) {
                // Tab 1: Home
                HomeView(authManager: authManager)
                    .tag(0)
                
                // Tab 2: Bible
                BibleView()
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .gesture(DragGesture().onChanged { _ in })
            }
            // Place the custom tab bar at the absolute bottom and, for the Bible tab only,
            // slide it down to cover the device's bottom inset
            .overlay(alignment: .bottom) {
                // Slightly lift the bar on Home so it matches visual baseline; fully cover inset on Bible
                CustomTabView(selectedTab: $selectedTab, showingChat: $showingChat)
                    .padding(.bottom, selectedTab == 1 ? -bottomSafeInset : 12)
                    .ignoresSafeArea(edges: .bottom)
            }
            .navigationDestination(isPresented: $showingChat) {
                ChatView(showingChat: $showingChat, selectedTab: $selectedTab, initialPrompt: initialChatPrompt)
                    .navigationBarHidden(true)
            }
        }
        // Hide the default navigation bar to remove the system top hairline
        .toolbar(.hidden, for: .navigationBar)
        // Keep ContentView's background synced when BibleView changes modes
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            if let saved = UserDefaults.standard.string(forKey: "bibleReadingMode"),
               let mode = ReadingMode(rawValue: saved) {
                bibleReadingMode = mode
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
        // No bottom safe-area inset. We're manually overlaying the bar instead.
    }
}

// MARK: - Custom Tab View
struct CustomTabView: View {
    @Binding var selectedTab: Int
    @Binding var showingChat: Bool
    var bottomInset: CGFloat = 0
    private let barHeight: CGFloat = 64
    
    var body: some View {
        ZStack(alignment: .top) {
            // Solid background and top divider inside the bar; include device bottom inset
            StyleGuide.backgroundBeige
            Rectangle()
                .fill(StyleGuide.backgroundBeige)
                .frame(height: max(0, bottomInset))
                .frame(maxHeight: .infinity, alignment: .bottom)
            Rectangle()
                .fill(StyleGuide.mainBrown.opacity(0.1))
                .frame(height: 1)
                .frame(maxHeight: .infinity, alignment: .top)
            
            // Tab buttons container
            HStack(spacing: 0) {
                Spacer()
                    .frame(maxWidth: 40)
                
                TabButton(
                    icon: "homeIcon",
                    title: "Home",
                    isSelected: selectedTab == 0,
                    isSystemIcon: false
                ) {
                    selectedTab = 0
                }
                
                Spacer()
                    .frame(maxWidth: 80)
                
                // Tab 2: Bible
                TabButton(
                    icon: "bibleIcon",
                    title: "Bible",
                    isSelected: selectedTab == 1,
                    isSystemIcon: false
                ) {
                    selectedTab = 1
                }
                
                Spacer()
                
                // Floating Circle Button
                FloatingTabButton(
                    icon: "aiIcon",
                    isSystemIcon: false
                ) {
                    showingChat = true
                }
                
                Spacer()
                    .frame(maxWidth: 20)
            }
            .padding(.horizontal, StyleGuide.spacing.lg)
            
            // Animated pill indicator below icons
            HStack(spacing: 0) {
                Spacer()
                    .frame(maxWidth: 40)
                
                Capsule()
                    .fill(StyleGuide.mainBrown)
                    .frame(width: 40, height: 2.5)
                    .offset(x: selectedTab == 0 ? 20 : 180)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: selectedTab)
                
                Spacer()
            }
            .padding(.horizontal, StyleGuide.spacing.lg)
            .padding(.top, 48)
        }
        .frame(height: barHeight + max(0, bottomInset))
        .ignoresSafeArea(edges: .bottom)
        .shadow(color: StyleGuide.mainBrown.opacity(0.25), radius: 4, x: 0, y: 0)
        
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let isSystemIcon: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Group {
                if isSystemIcon {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                } else {
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                }
            }
            .foregroundColor(isSelected ? StyleGuide.mainBrown : StyleGuide.mainBrown.opacity(0.5))
            .frame(width: 80, height: 56)
            .padding(.bottom, 8)
            .scaleEffect(isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .frame(width: 80, height: 56)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Floating Tab Button
struct FloatingTabButton: View {
    let icon: String
    let isSystemIcon: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
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
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .frame(width: 60, height: 60)
        .contentShape(Circle())
        .offset(y: -30) // Center of circle aligned with top of tab bar
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}




#Preview {
    ContentView()
        .environmentObject(AuthManager())
}

 
