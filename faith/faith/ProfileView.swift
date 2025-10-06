//
//  ProfileView.swift
//  faith
//
//  Profile view displaying user information and settings
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var userDataManager: UserDataManager
    @State private var showCopiedFeedback = false
    @State private var showingEditNote = false
    @State private var selectedNote: VerseNote? = nil
    
    var body: some View {
        ZStack {
            // Background
            Image("background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea(.all)
            
            ScrollView {
                VStack(spacing: StyleGuide.spacing.xl) {
                    // Top spacing
                    Spacer()
                        .frame(height: 20)
                    
                    // Profile Header
                    VStack(spacing: StyleGuide.spacing.md) {
                        // Profile Icon
                        ZStack {
                            Circle()
                                .fill(StyleGuide.gold.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(StyleGuide.gold)
                        }
                        
                        // User Name with Copy Button
                        Button(action: {
                            let username = userDataManager.getDisplayName()
                            UIPasteboard.general.string = username
                            
                            // Show feedback
                            withAnimation {
                                showCopiedFeedback = true
                            }
                            
                            // Hide after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showCopiedFeedback = false
                                }
                            }
                            
                            // Haptic feedback
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }) {
                            HStack(spacing: 8) {
                                Text(userDataManager.getDisplayName())
                                    .font(StyleGuide.merriweather(size: 28, weight: .bold))
                                    .foregroundColor(StyleGuide.mainBrown)
                                
                                Image(systemName: showCopiedFeedback ? "checkmark.circle.fill" : "doc.on.doc")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(showCopiedFeedback ? .green : StyleGuide.mainBrown.opacity(0.5))
                                    .offset(y: -6)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // User Stats
                        HStack(spacing: StyleGuide.spacing.xl) {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image("streak")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("\(userDataManager.getCurrentStreak())")
                                        .font(StyleGuide.merriweather(size: 24, weight: .bold))
                                        .foregroundColor(StyleGuide.gold)
                                }
                                
                                Text("Day Streak")
                                    .font(StyleGuide.merriweather(size: 12, weight: .regular))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                            }
                            
                            Rectangle()
                                .fill(StyleGuide.mainBrown.opacity(0.2))
                                .frame(width: 1, height: 40)
                            
                            VStack(spacing: 4) {
                                Text("\(userDataManager.userProgress?.total_xp ?? 0)")
                                    .font(StyleGuide.merriweather(size: 24, weight: .bold))
                                    .foregroundColor(StyleGuide.mainBrown)
                                
                                Text("Total XP")
                                    .font(StyleGuide.merriweather(size: 12, weight: .regular))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                            }
                        }
                    }
                    .padding(.vertical, StyleGuide.spacing.xl)
                    .padding(.horizontal, StyleGuide.spacing.lg)
                    .background(StyleGuide.backgroundBeige)
                    .cornerRadius(16)
                    .shadow(color: StyleGuide.shadows.md, radius: 8, x: 0, y: 4)
                    .padding(.horizontal, StyleGuide.spacing.lg)
                    
                    // Badges Section
                    VStack(spacing: StyleGuide.spacing.md) {
                        HStack {
                            Text("Badges")
                                .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                                .textCase(.uppercase)
                            
                            Spacer()
                        }
                        .padding(.horizontal, StyleGuide.spacing.lg)
                        
                        // Badge Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            // Example badges
                            BadgeItem(icon: "star.fill", title: "First Step", color: StyleGuide.gold, isEarned: true)
                            BadgeItem(icon: "flame.fill", title: "7 Day", color: .orange, isEarned: false)
                            BadgeItem(icon: "book.fill", title: "Scholar", color: .blue, isEarned: false)
                            BadgeItem(icon: "heart.fill", title: "Devoted", color: .red, isEarned: false)
                        }
                        .padding(.horizontal, StyleGuide.spacing.lg)
                    }
                    
                    // Notes Section
                    VStack(spacing: StyleGuide.spacing.md) {
                        HStack {
                            Text("My Notes")
                                .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                                .textCase(.uppercase)
                            
                            Spacer()
                            
                            let uniqueVerses = Set(userDataManager.verseNotes.map { "\($0.book):\($0.chapter):\($0.verse)" }).count
                            Text("\(uniqueVerses)")
                                .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.4))
                        }
                        .padding(.horizontal, StyleGuide.spacing.lg)
                        
                        if userDataManager.verseNotes.isEmpty {
                            // Empty state
                            VStack(spacing: StyleGuide.spacing.sm) {
                                Image(systemName: "note.text")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.3))
                                
                                Text("No notes yet")
                                    .font(StyleGuide.merriweather(size: 14, weight: .medium))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                                
                                Text("Add notes to verses while reading")
                                    .font(StyleGuide.merriweather(size: 12, weight: .regular))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.4))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, StyleGuide.spacing.xl)
                            .background(StyleGuide.backgroundBeige)
                            .cornerRadius(12)
                            .shadow(color: StyleGuide.shadows.sm, radius: 4, x: 0, y: 2)
                            .padding(.horizontal, StyleGuide.spacing.lg)
                        } else {
                            // Group notes by verse
                            let groupedNotes = Dictionary(grouping: userDataManager.verseNotes) { note in
                                "\(note.book):\(note.chapter):\(note.verse)"
                            }
                            let sortedGroups = groupedNotes.sorted { 
                                guard let note1 = $0.value.first, let note2 = $1.value.first else { return false }
                                return note1.created_at > note2.created_at
                            }
                            
                            // Notes list with improved styling
                            VStack(spacing: StyleGuide.spacing.sm) {
                                ForEach(sortedGroups.prefix(5), id: \.key) { key, notesForVerse in
                                    if let firstNote = notesForVerse.first {
                                        Button(action: {
                                            print("📝 NOTE BUTTON CLICKED")
                                            print("   Note: \(firstNote.verseReference)")
                                            print("   showingEditNote before: \(showingEditNote)")
                                            selectedNote = firstNote
                                            showingEditNote = true
                                            print("   showingEditNote after: \(showingEditNote)")
                                            print("   selectedNote: \(selectedNote?.verseReference ?? "none")")
                                        }) {
                                            HStack(alignment: .top, spacing: 12) {
                                                // Note icon
                                                ZStack(alignment: .topTrailing) {
                                                    Image(systemName: "note.text")
                                                        .font(.system(size: 18, weight: .medium))
                                                        .foregroundColor(StyleGuide.gold)
                                                        .frame(width: 28)
                                                    
                                                    // Badge for multiple notes
                                                    if notesForVerse.count > 1 {
                                                        Text("\(notesForVerse.count)")
                                                            .font(StyleGuide.merriweather(size: 9, weight: .bold))
                                                            .foregroundColor(.white)
                                                            .padding(3)
                                                            .background(Circle().fill(StyleGuide.gold))
                                                            .offset(x: 8, y: -4)
                                                    }
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 6) {
                                                    // Verse reference
                                                    HStack(spacing: 8) {
                                                        Text(firstNote.verseReference)
                                                            .font(StyleGuide.merriweather(size: 14, weight: .bold))
                                                            .foregroundColor(StyleGuide.mainBrown)
                                                        
                                                        if let translation = firstNote.translation {
                                                            Text(translation)
                                                                .font(StyleGuide.merriweather(size: 10, weight: .semibold))
                                                                .foregroundColor(StyleGuide.gold.opacity(0.8))
                                                                .padding(.horizontal, 6)
                                                                .padding(.vertical, 2)
                                                                .background(
                                                                    Capsule()
                                                                        .fill(StyleGuide.gold.opacity(0.15))
                                                                )
                                                        }
                                                    }
                                                    
                                                    // Show note count or single note text
                                                    if notesForVerse.count > 1 {
                                                        Text("\(notesForVerse.count) notes")
                                                            .font(StyleGuide.merriweather(size: 13, weight: .medium))
                                                            .foregroundColor(StyleGuide.mainBrown.opacity(0.75))
                                                    } else {
                                                        Text(firstNote.note_text)
                                                            .font(StyleGuide.merriweather(size: 13, weight: .regular))
                                                            .foregroundColor(StyleGuide.mainBrown.opacity(0.75))
                                                            .lineLimit(2)
                                                            .lineSpacing(3)
                                                    }
                                                    
                                                    // Date with relative time
                                                    Text(firstNote.relativeDate)
                                                        .font(StyleGuide.merriweather(size: 11, weight: .medium))
                                                        .foregroundColor(StyleGuide.mainBrown.opacity(0.45))
                                                }
                                                
                                                Spacer()
                                                
                                                // Chevron indicator
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.25))
                                            }
                                            .padding(StyleGuide.spacing.md)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .fill(Color.white.opacity(0.7))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .stroke(StyleGuide.mainBrown.opacity(0.08), lineWidth: 1)
                                            )
                                            .shadow(color: StyleGuide.shadows.sm, radius: 3, x: 0, y: 2)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                
                                // "View All" button if more than 5 verse groups
                                if sortedGroups.count > 5 {
                                    Button(action: {
                                        // TODO: Navigate to all notes view
                                    }) {
                                        HStack {
                                            Image(systemName: "square.grid.2x2")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(StyleGuide.gold)
                                            
                                            Text("View All (\(sortedGroups.count) verses)")
                                                .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                                                .foregroundColor(StyleGuide.gold)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(StyleGuide.gold.opacity(0.7))
                                        }
                                        .padding(StyleGuide.spacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(StyleGuide.gold.opacity(0.12))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(StyleGuide.gold.opacity(0.3), lineWidth: 1.5)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, StyleGuide.spacing.lg)
                        }
                    }
                    
                    // Friends Section
                    VStack(spacing: StyleGuide.spacing.md) {
                        Text("Friends")
                            .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, StyleGuide.spacing.lg)
                        
                        VStack(spacing: 0) {
                            // Manage Friends Button
                            Button(action: {
                                // TODO: Navigate to friends management
                            }) {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                                    
                                    Text("Manage Friends")
                                        .font(StyleGuide.merriweather(size: 16, weight: .medium))
                                        .foregroundColor(StyleGuide.mainBrown)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(StyleGuide.mainBrown.opacity(0.3))
                                }
                                .padding(.horizontal, StyleGuide.spacing.lg)
                                .padding(.vertical, StyleGuide.spacing.md)
                                .background(StyleGuide.backgroundBeige)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .cornerRadius(12)
                        .shadow(color: StyleGuide.shadows.sm, radius: 4, x: 0, y: 2)
                        .padding(.horizontal, StyleGuide.spacing.lg)
                    }
                    
                    // Account Section
                    VStack(spacing: StyleGuide.spacing.md) {
                        Text("Account")
                            .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, StyleGuide.spacing.lg)
                        
                        VStack(spacing: 0) {
                            // Sign Out Button
                            Button(action: {
                                Task {
                                    await authManager.signOut()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                                    
                                    Text("Sign Out")
                                        .font(StyleGuide.merriweather(size: 16, weight: .medium))
                                        .foregroundColor(StyleGuide.mainBrown)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(StyleGuide.mainBrown.opacity(0.3))
                                }
                                .padding(.horizontal, StyleGuide.spacing.lg)
                                .padding(.vertical, StyleGuide.spacing.md)
                                .background(StyleGuide.backgroundBeige)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .cornerRadius(12)
                        .shadow(color: StyleGuide.shadows.sm, radius: 4, x: 0, y: 2)
                        .padding(.horizontal, StyleGuide.spacing.lg)
                    }
                    
                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(StyleGuide.merriweather(size: 18, weight: .semibold))
                    .foregroundColor(StyleGuide.mainBrown)
            }
        }
        .sheet(isPresented: $showingEditNote) {
            Group {
                if let note = selectedNote {
                    NoteEditorFromProfileView(
                        note: note,
                        userDataManager: userDataManager,
                        onDismiss: {
                            print("📋 onDismiss called")
                            showingEditNote = false
                            selectedNote = nil
                        }
                    )
                    .onAppear {
                        print("📋 Sheet content appeared with note: \(note.verseReference)")
                    }
                } else {
                    Text("No note selected")
                        .onAppear {
                            print("❌ Sheet showing error - selectedNote is nil")
                        }
                }
            }
        }
        .onChange(of: showingEditNote) { newValue in
            print("🔔 showingEditNote changed to: \(newValue)")
            print("   selectedNote: \(selectedNote?.verseReference ?? "nil")")
        }
        .onAppear {
            print("👤 ProfileView appeared - refreshing data")
            // Refresh user data to get latest notes and stats
            Task {
                await userDataManager.fetchUserData()
            }
        }
    }
}

// MARK: - Note Editor Wrapper for ProfileView
/// Loads the verse and shows the note editor
struct NoteEditorFromProfileView: View {
    let note: VerseNote
    @ObservedObject var userDataManager: UserDataManager
    let onDismiss: () -> Void
    
    @StateObject private var bibleManager = BibleManager()
    @State private var loadedVerse: BibleVerse?
    
    var body: some View {
        contentView
            .onAppear {
                print("🔄 NoteEditorFromProfileView appeared")
                print("   Note: book=\(note.book), chapter=\(note.chapter), verse=\(note.verse)")
                print("   Loading verse: \(note.verseReference)")
                bibleManager.loadVerses(book: note.book, chapter: note.chapter)
                print("   BibleManager.isLoading: \(bibleManager.isLoading)")
                print("   BibleManager.verses.count: \(bibleManager.verses.count)")
                print("   BibleManager.errorMessage: \(bibleManager.errorMessage ?? "none")")
            }
            .onChange(of: bibleManager.verses) { verses in
                print("📖 Verses changed: \(verses.count) verses loaded")
                findVerse(in: verses)
                print("   loadedVerse found: \(loadedVerse != nil)")
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if let verse = loadedVerse {
            AddNoteView(
                verse: verse,
                bibleManager: bibleManager,
                userDataManager: userDataManager,
                onDismiss: onDismiss
            )
        } else if bibleManager.isLoading {
            loadingView
        } else if let errorMsg = bibleManager.errorMessage {
            errorView(message: errorMsg)
        } else {
            loadingView
        }
    }
    
    private var loadingView: some View {
        NavigationView {
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: StyleGuide.mainBrown))
                Text("Loading verse...")
                    .font(StyleGuide.merriweather(size: 14))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Image("background").resizable().aspectRatio(contentMode: .fill).ignoresSafeArea())
            .navigationTitle("Loading...")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(StyleGuide.mainBrown)
                }
            }
        }
    }
    
    private func errorView(message: String) -> some View {
        NavigationView {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.4))
                Text("Error loading verse")
                    .font(StyleGuide.merriweather(size: 14))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                Text(message)
                    .font(StyleGuide.merriweather(size: 12))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Image("background").resizable().aspectRatio(contentMode: .fill).ignoresSafeArea())
            .navigationTitle("Error")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onDismiss()
                    }
                    .foregroundColor(StyleGuide.mainBrown)
                }
            }
        }
    }
    
    private func findVerse(in verses: [BibleVerse]) {
        print("🔍 Searching for verse in \(verses.count) verses")
        print("   Looking for: book=\(note.book), chapter=\(note.chapter), verse=\(note.verse)")
        
        if let verse = verses.first(where: { $0.book == note.book && $0.chapter == note.chapter && $0.verse == note.verse }) {
            print("✅ Found verse: \(verse.formattedReference)")
            loadedVerse = verse
        } else if !verses.isEmpty {
            print("⚠️ Verse not found in loaded verses")
            print("   First verse: book=\(verses.first?.book ?? -1), chapter=\(verses.first?.chapter ?? -1), verse=\(verses.first?.verse ?? -1)")
        } else {
            print("⚠️ No verses loaded yet")
        }
    }
}

// MARK: - Badge Item
struct BadgeItem: View {
    let icon: String
    let title: String
    let color: Color
    let isEarned: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isEarned ? color.opacity(0.15) : StyleGuide.mainBrown.opacity(0.05))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isEarned ? color : StyleGuide.mainBrown.opacity(0.3))
            }
            
            Text(title)
                .font(StyleGuide.merriweather(size: 10, weight: .medium))
                .foregroundColor(isEarned ? StyleGuide.mainBrown : StyleGuide.mainBrown.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .opacity(isEarned ? 1.0 : 0.6)
    }
}

#Preview {
    NavigationStack {
        ProfileView(userDataManager: UserDataManager(supabase: AuthManager().supabase, authManager: AuthManager()))
            .environmentObject(AuthManager())
    }
}

