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
    private let barHeight: CGFloat = 72
    
    var body: some View {
        HStack(spacing: 20) {
            Spacer()
            
            // Center capsule with Home, Bible, and Cross buttons
            Group {
                HStack(spacing: 20) {
                    TabButton(
                        icon: "homeIcon",
                        title: "Home",
                        isSelected: selectedTab == 0,
                        isSystemIcon: false
                    ) {
                        selectedTab = 0
                    }
                    
                    TabButton(
                        icon: "bibleIcon",
                        title: "Bible",
                        isSelected: selectedTab == 1,
                        isSystemIcon: false
                    ) {
                        selectedTab = 1
                    }
                    
                    // Cross button integrated into menu
                    IntegratedCrossButton {
                        showingChat = true
                    }
                }
                .padding(.leading, 14)
                .padding(.trailing, 14)
                .padding(.vertical, 10)
            }
            .modifier(GlassTabBarModifier())
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
            
            Spacer()
        }
        .padding(.horizontal, StyleGuide.spacing.lg)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(edges: .bottom)
        
    }
}

// MARK: - Glass Effect Modifiers
struct GlassTabBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.tint(StyleGuide.backgroundBeige.opacity(0.5)).interactive())
                .clipShape(Capsule())
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .fill(StyleGuide.backgroundBeige.opacity(0.1))
                        .allowsHitTesting(false)
                )
        }
    }
}

struct GlassButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.tint(StyleGuide.mainBrown.opacity(0.85)).interactive())
                .clipShape(Circle())
        } else {
            content
                .background {
                    ZStack {
                        Circle()
                            .fill(StyleGuide.mainBrown.opacity(0.85))
                            .frame(width: 64, height: 64)
                    }
                    .background(.thinMaterial, in: Circle())
                    .allowsHitTesting(false)
                }
        }
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
                        .font(.system(size: 28))
                } else {
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                }
            }
            .foregroundColor(isSelected ? StyleGuide.mainBrown : StyleGuide.mainBrown.opacity(0.4))
            .scaleEffect(isSelected ? 1.0 : 0.9)
            .scaleEffect(isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        }
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
    }
}

// MARK: - Integrated Cross Button
struct IntegratedCrossButton: View {
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image("cross")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(StyleGuide.mainBrown)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .contentShape(Circle())
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

// MARK: - Floating Tab Button
struct FloatingTabButton: View {
    let icon: String
    let isSystemIcon: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image("cross")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .modifier(GlassButtonModifier())
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .frame(width: 64, height: 64)
        .contentShape(Circle())
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

 
