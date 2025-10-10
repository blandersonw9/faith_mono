
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
    @EnvironmentObject var userDataManager: UserDataManager
    @State private var selectedTab = 0
    @State private var showingChat = false
    @State private var initialChatPrompt: String? = nil
    @Environment(\.scenePhase) private var scenePhase
    // Mirror BibleView's reading mode so we can color the parent background
    @State private var bibleReadingMode: ReadingMode = {
        if let saved = UserDefaults.standard.string(forKey: "bibleReadingMode"),
           let mode = ReadingMode(rawValue: saved) {
            return mode
        }
        return .day
    }()
    
    // Detect if running on iPad or larger screen
    private var isIPad: Bool {
        // Check both idiom and screen size to catch iPad compatibility mode
        let idiom = UIDevice.current.userInterfaceIdiom == .pad
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let largestDimension = max(screenWidth, screenHeight)
        // iPad screens are typically 1024+ points in their largest dimension
        return idiom || largestDimension >= 1024
    }
    
    // Bottom safe-area inset (for painting under the home indicator)
    private var bottomSafeInset: CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.bottom
        }
        return 0
    }
    
    var body: some View {
        let _ = print("🔍 Device idiom: \(UIDevice.current.userInterfaceIdiom.rawValue), Screen: \(UIScreen.main.bounds.size), isIPad: \(isIPad)")
        
        NavigationStack {
            if isIPad {
                // iPad: Use VStack to guarantee tab bar visibility
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        ZStack {
                            // Conditional background based on selected tab
                            if selectedTab == 0 {
                                Image("background")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                bibleReadingMode.backgroundColor
                            }
                            
                            // Main Content Area
                            ZStack {
                                HomeView()
                                    .environmentObject(userDataManager)
                                    .environmentObject(bibleNavigator)
                                    .opacity(selectedTab == 0 ? 1 : 0)
                                    .zIndex(selectedTab == 0 ? 1 : 0)
                                
                                BibleView()
                                    .environmentObject(userDataManager)
                                    .environmentObject(bibleNavigator)
                                    .opacity(selectedTab == 1 ? 1 : 0)
                                    .zIndex(selectedTab == 1 ? 1 : 0)
                            }
                        }
                        .frame(height: geo.size.height - 84) // Leave 84pt for tab bar (72pt + 12pt padding)
                        
                        // Tab bar at bottom (guaranteed visible)
                        CustomTabView(selectedTab: $selectedTab, showingChat: $showingChat)
                            .frame(height: 72)
                            .padding(.bottom, 12)
                    }
                }
                .navigationDestination(isPresented: $showingChat) {
                    ChatView(showingChat: $showingChat, selectedTab: $selectedTab, initialPrompt: initialChatPrompt)
                        .navigationBarHidden(true)
                }
                .toolbar(.hidden, for: .navigationBar)
            } else {
                // iPhone: Original overlay approach
                ZStack {
                    // Conditional background based on selected tab
                    if selectedTab == 0 {
                        Image("background")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .ignoresSafeArea(.all)
                    } else {
                        bibleReadingMode.backgroundColor
                            .ignoresSafeArea(.all)
                    }
                    
                    // Main Content Area
                    ZStack {
                        HomeView()
                            .environmentObject(userDataManager)
                            .environmentObject(bibleNavigator)
                            .opacity(selectedTab == 0 ? 1 : 0)
                            .zIndex(selectedTab == 0 ? 1 : 0)
                        
                        BibleView()
                            .environmentObject(userDataManager)
                            .environmentObject(bibleNavigator)
                            .opacity(selectedTab == 1 ? 1 : 0)
                            .zIndex(selectedTab == 1 ? 1 : 0)
                    }
                }
                .overlay(alignment: .bottom) {
                    CustomTabView(selectedTab: $selectedTab, showingChat: $showingChat)
                        .padding(.bottom, selectedTab == 1 ? -bottomSafeInset : 12)
                        .ignoresSafeArea(edges: .bottom)
                }
                .navigationDestination(isPresented: $showingChat) {
                    ChatView(showingChat: $showingChat, selectedTab: $selectedTab, initialPrompt: initialChatPrompt)
                        .navigationBarHidden(true)
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
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
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                print("📱 App became active - refreshing user data")
                // Refresh user data when app becomes active
                Task {
                    await userDataManager.fetchUserData()
                }
            }
        }
        .onChange(of: authManager.isAuthenticated) { isAuth in
            if isAuth {
                print("📱 Auth status changed to authenticated - loading user data")
                Task {
                    await userDataManager.fetchUserData()
                }
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
    @State private var homeButtonCenter: CGFloat = 0
    @State private var bibleButtonCenter: CGFloat = 0
    
    // Detect if running on iPad or larger screen
    private var isIPad: Bool {
        // Check both idiom and screen size to catch iPad compatibility mode
        let idiom = UIDevice.current.userInterfaceIdiom == .pad
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let largestDimension = max(screenWidth, screenHeight)
        // iPad screens are typically 1024+ points in their largest dimension
        return idiom || largestDimension >= 1024
    }
    
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
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ButtonCenterPreferenceKey.self,
                            value: ["home": geo.frame(in: .named("tabBar")).midX]
                        )
                    }
                )
                
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
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ButtonCenterPreferenceKey.self,
                            value: ["bible": geo.frame(in: .named("tabBar")).midX]
                        )
                    }
                )
                
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
            .onPreferenceChange(ButtonCenterPreferenceKey.self) { preferences in
                if let home = preferences["home"] {
                    homeButtonCenter = home
                }
                if let bible = preferences["bible"] {
                    bibleButtonCenter = bible
                }
            }
            
            // Animated pill indicator below icons - responsive positioning
            if homeButtonCenter > 0 && bibleButtonCenter > 0 {
                HStack(spacing: 0) {
                    Capsule()
                        .fill(StyleGuide.mainBrown)
                        .frame(width: 40, height: 2.5)
                        .position(
                            x: selectedTab == 0 ? homeButtonCenter : bibleButtonCenter,
                            y: 42 + 1.25
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: selectedTab)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .coordinateSpace(name: "tabBar")
        .frame(height: barHeight + (isIPad ? 0 : max(0, bottomInset)))
        .ignoresSafeArea(edges: isIPad ? [] : .bottom)
        .shadow(color: StyleGuide.mainBrown.opacity(0.25), radius: 4, x: 0, y: 0)
        
    }
}

// MARK: - Preference Key for Button Positions
struct ButtonCenterPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]
    
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { $1 }
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
            .padding(.bottom, 10)
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

 
