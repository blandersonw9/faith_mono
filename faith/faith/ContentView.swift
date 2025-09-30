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
                HomeView()
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
        #if DEBUG
        // Visualize the bottom safe-area and log its value
        .overlay(SafeAreaDebugOverlay(), alignment: .bottom)
        .onAppear { print("[DEBUG] bottomSafeInset:", bottomSafeInset) }
        #endif
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
        .frame(height: barHeight + max(0, bottomInset))
        .ignoresSafeArea(edges: .bottom)
        .shadow(color: StyleGuide.mainBrown.opacity(0.25), radius: 4, x: 0, y: 0)
        #if DEBUG
        .background(Color.yellow.opacity(0.12))
        .overlay(
            GeometryReader { g in
                Color.clear
                    .onAppear {
                        let minY = g.frame(in: .global).minY
                        print("[DEBUG] CustomTabView height:", g.size.height, "bottomInset:", bottomInset, "global minY:", minY)
                    }
            }
            .allowsHitTesting(false)
        )
        .border(Color.green, width: 1)
        #endif
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
                .font(.system(size: 22))
                .foregroundColor(isSelected ? StyleGuide.mainBrown : StyleGuide.mainBrown.opacity(0.5))
                .frame(width: 80, height: 56, alignment: .top)
                .padding(.top, 10)
        }
        .frame(width: 80, height: 56)
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

#if DEBUG
private struct SafeAreaDebugOverlay: View {
    var body: some View {
        GeometryReader { g in
            VStack(spacing: 0) {
                Text("inset: \(Int(g.safeAreaInsets.bottom))")
                    .font(.system(size: 9))
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background(Color.red.opacity(0.85))
                    .foregroundColor(.white)
                Color.red.opacity(0.25)
                    .frame(height: g.safeAreaInsets.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
        }
    }
}
#endif
