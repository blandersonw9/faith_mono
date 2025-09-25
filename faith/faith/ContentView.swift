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
    @State private var selectedTab = 0
    @State private var showingChat = false
    
    var body: some View {
        NavigationStack {
            ZStack {
            // Background Image
            Image("background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea(.all)
            
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
                CustomTabView(selectedTab: $selectedTab, showingChat: $showingChat)
            }
            }
            .navigationDestination(isPresented: $showingChat) {
                ChatView(showingChat: $showingChat)
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
                    icon: "person.circle.fill"
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
                )
                .shadow(color: StyleGuide.shadows.md, radius: 4, x: 0, y: 2)
        }
        .frame(width: 60, height: 60)
        .contentShape(Circle())
        .offset(y: -30) // Center of circle aligned with top of tab bar
    }
}



struct BibleView: View {
    @StateObject private var bibleManager = BibleManager()
    @State private var showingBookPicker = false
    @State private var showingChapterPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with book/chapter selector
            HStack {
                Button(action: {
                    showingBookPicker = true
                }) {
                    HStack {
                        Text(bibleManager.currentBook > 0 ? BibleManager.bookNames[bibleManager.currentBook] ?? "Select Book" : "Select Book")
                            .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                            .foregroundColor(StyleGuide.mainBrown)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(StyleGuide.mainBrown)
                    }
                    .padding(.horizontal, StyleGuide.spacing.md)
                    .padding(.vertical, StyleGuide.spacing.sm)
                    .background(Color.white)
                    .cornerRadius(StyleGuide.cornerRadius.sm)
                    .shadow(color: StyleGuide.shadows.sm, radius: 2, x: 0, y: 1)
                }
                
                Spacer()
                
                Button(action: {
                    showingChapterPicker = true
                }) {
                    HStack {
                        Text("Chapter \(bibleManager.currentChapter)")
                            .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                            .foregroundColor(StyleGuide.mainBrown)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(StyleGuide.mainBrown)
                    }
                    .padding(.horizontal, StyleGuide.spacing.md)
                    .padding(.vertical, StyleGuide.spacing.sm)
                    .background(Color.white)
                    .cornerRadius(StyleGuide.cornerRadius.sm)
                    .shadow(color: StyleGuide.shadows.sm, radius: 2, x: 0, y: 1)
                }
            }
            .padding(.horizontal, StyleGuide.spacing.lg)
            .padding(.top, StyleGuide.spacing.md)
            
            // Bible content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: StyleGuide.spacing.md) {
                    if bibleManager.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: StyleGuide.mainBrown))
                            Spacer()
                        }
                        .padding(.top, StyleGuide.spacing.xl)
                    } else if let errorMessage = bibleManager.errorMessage {
                        Text(errorMessage)
                            .font(StyleGuide.merriweather(size: 14))
                            .foregroundColor(.red)
        .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(StyleGuide.cornerRadius.sm)
                            .padding(.horizontal, StyleGuide.spacing.lg)
                    } else {
                        ForEach(bibleManager.verses, id: \.id) { verse in
                            HStack(alignment: .top, spacing: StyleGuide.spacing.sm) {
                                Text("\(verse.verse)")
                                    .font(StyleGuide.merriweather(size: 12, weight: .bold))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                                    .frame(width: 20, alignment: .trailing)
                                
                                Text(verse.text)
                                    .font(StyleGuide.merriweather(size: 16))
                                    .foregroundColor(StyleGuide.mainBrown)
                                    .lineSpacing(4)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.horizontal, StyleGuide.spacing.lg)
                        }
                    }
                }
                .padding(.top, StyleGuide.spacing.md)
            }
        }
        .background(StyleGuide.backgroundBeige.ignoresSafeArea(.all))
        .onAppear {
            if bibleManager.verses.isEmpty {
                bibleManager.loadVerses(book: 1, chapter: 1) // Load Genesis 1 by default
            }
        }
        .sheet(isPresented: $showingBookPicker) {
            BookPickerView(bibleManager: bibleManager)
        }
        .sheet(isPresented: $showingChapterPicker) {
            ChapterPickerView(bibleManager: bibleManager)
        }
    }
}

// MARK: - Book Picker
struct BookPickerView: View {
    @ObservedObject var bibleManager: BibleManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(bibleManager.getAvailableBooks(), id: \.id) { book in
                Button(action: {
                    bibleManager.loadVerses(book: book.id, chapter: 1)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(book.name)
                        .font(StyleGuide.merriweather(size: 16))
                        .foregroundColor(StyleGuide.mainBrown)
                }
            }
            .navigationTitle("Select Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Chapter Picker
struct ChapterPickerView: View {
    @ObservedObject var bibleManager: BibleManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(bibleManager.getAvailableChapters(for: bibleManager.currentBook), id: \.self) { chapter in
                Button(action: {
                    bibleManager.loadVerses(book: bibleManager.currentBook, chapter: chapter)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Chapter \(chapter)")
                        .font(StyleGuide.merriweather(size: 16))
                        .foregroundColor(StyleGuide.mainBrown)
                }
            }
            .navigationTitle("Select Chapter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
