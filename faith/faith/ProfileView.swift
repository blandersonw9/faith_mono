//
//  ProfileView.swift
//  faith
//
//  Profile view displaying user information and settings
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var bibleNavigator: BibleNavigator
    @ObservedObject var userDataManager: UserDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedFeedback = false
    @State private var showingEditNote = false
    @State private var selectedNote: VerseNote? = nil
    @State private var showingEditProfile = false
    
    // DEBUG: Test streak values
    @State private var debugStreakOverride: Int? = nil
    @State private var showDebugControls = false
    
    // Badge celebration
    @State private var celebratingBadge: StreakBadge? = nil
    @State private var showBadgeDetail: StreakBadge? = nil
    
    // Delete account confirmation
    @State private var showDeleteConfirmation = false
    @State private var isDeletingAccount = false
    
    private var displayStreak: Int {
        debugStreakOverride ?? userDataManager.getCurrentStreak()
    }
    
    private func nextBadge(for currentStreak: Int) -> StreakBadge? {
        StreakBadge.allBadges.first(where: { $0.daysRequired > currentStreak })
    }
    
    private func progressToNext(for currentStreak: Int) -> Double {
        guard let next = nextBadge(for: currentStreak) else {
            return 1.0 // All badges earned
        }
        
        // Find the previous badge milestone
        let previousMilestone = StreakBadge.allBadges
            .filter { $0.daysRequired <= currentStreak }
            .last?.daysRequired ?? 0
        
        let range = Double(next.daysRequired - previousMilestone)
        let progress = Double(currentStreak - previousMilestone)
        
        return min(progress / range, 1.0)
    }
    
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
                        
                        // User Name with Copy and Edit Buttons
                        HStack(spacing: 12) {
                            // Copy button
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
                            
                            // Edit button
                            Button(action: {
                                showingEditProfile = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(StyleGuide.gold)
                                    .offset(y: -6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // User Stats
                        HStack(spacing: StyleGuide.spacing.xl) {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image("streak")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("\(displayStreak)")
                                        .font(StyleGuide.merriweather(size: 24, weight: .bold))
                                        .foregroundColor(debugStreakOverride != nil ? .orange : StyleGuide.gold)
                                }
                                
                                Text("Day Streak")
                                    .font(StyleGuide.merriweather(size: 12, weight: .regular))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                            }
                            .onLongPressGesture {
                                withAnimation {
                                    showDebugControls.toggle()
                                }
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
                    
                    // DEBUG Controls
                    if showDebugControls {
                        VStack(spacing: StyleGuide.spacing.md) {
                            HStack {
                                Text("🧪 Debug: Test Streak")
                                    .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                                    .foregroundColor(.orange)
                                    .textCase(.uppercase)
                                
                                Spacer()
                                
                                Button(action: {
                                    debugStreakOverride = nil
                                }) {
                                    Text("Reset")
                                        .font(StyleGuide.merriweather(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(StyleGuide.gold)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, StyleGuide.spacing.lg)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Streak: \(debugStreakOverride ?? userDataManager.getCurrentStreak())")
                                        .font(StyleGuide.merriweather(size: 16, weight: .bold))
                                        .foregroundColor(StyleGuide.mainBrown)
                                    
                                    Spacer()
                                }
                                
                                Stepper(value: Binding(
                                    get: { debugStreakOverride ?? userDataManager.getCurrentStreak() },
                                    set: { debugStreakOverride = $0 }
                                ), in: 0...400) {
                                    EmptyView()
                                }
                                
                                // Quick test buttons
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach([0, 2, 7, 14, 30, 60, 100, 200, 365], id: \.self) { days in
                                            Button(action: {
                                                debugStreakOverride = days
                                            }) {
                                                Text("\(days)")
                                                    .font(StyleGuide.merriweather(size: 12, weight: .semibold))
                                                    .foregroundColor(debugStreakOverride == days ? .white : StyleGuide.mainBrown)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(debugStreakOverride == days ? .orange : Color.white.opacity(0.5))
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, StyleGuide.spacing.lg)
                                }
                                
                                // Test celebration button
                                Button(action: {
                                    if let badge = StreakBadge.allBadges.first(where: { $0.daysRequired <= displayStreak }) {
                                        celebratingBadge = badge
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "party.popper.fill")
                                            .font(.system(size: 14, weight: .medium))
                                        
                                        Text("Test Badge Celebration")
                                            .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(StyleGuide.gold)
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal, StyleGuide.spacing.lg)
                                .padding(.top, 8)
                            }
                            .padding(StyleGuide.spacing.md)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, StyleGuide.spacing.lg)
                        }
                    }
                    
                    // Badges Section
                    VStack(spacing: StyleGuide.spacing.md) {
                        HStack {
                            Text("Streak Badges")
                                .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                                .textCase(.uppercase)
                            
                            Spacer()
                            
                            // Badge count
                            let earnedCount = StreakBadge.allBadges.filter { displayStreak >= $0.daysRequired }.count
                            Text("\(earnedCount)/\(StreakBadge.allBadges.count)")
                                .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                                .foregroundColor(StyleGuide.gold)
                        }
                        .padding(.horizontal, StyleGuide.spacing.lg)
                        
                        // Badge Grid
                        let currentStreak = displayStreak
                        let nextBadge = nextBadge(for: currentStreak)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 16) {
                            ForEach(StreakBadge.allBadges) { badge in
                                Button(action: {
                                    showBadgeDetail = badge
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }) {
                                    BadgeItemWithProgress(
                                        badge: badge,
                                        isEarned: currentStreak >= badge.daysRequired,
                                        currentStreak: currentStreak,
                                        isNextBadge: nextBadge?.id == badge.id,
                                        progress: nextBadge?.id == badge.id ? progressToNext(for: currentStreak) : 0
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
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
                    
                    // Saved Verses Section
                    VStack(spacing: StyleGuide.spacing.md) {
                        HStack {
                            Text("Saved Verses")
                                .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                                .textCase(.uppercase)
                            
                            Spacer()
                            
                            Text("\(userDataManager.savedVerses.count)")
                                .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.4))
                        }
                        .padding(.horizontal, StyleGuide.spacing.lg)
                        
                        if userDataManager.savedVerses.isEmpty {
                            // Empty state
                            VStack(spacing: StyleGuide.spacing.sm) {
                                Image(systemName: "heart")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.3))
                                
                                Text("No saved verses yet")
                                    .font(StyleGuide.merriweather(size: 14, weight: .medium))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                                
                                Text("Save verses while reading the Bible")
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
                            // Saved verses list
                            VStack(spacing: StyleGuide.spacing.sm) {
                                ForEach(userDataManager.savedVerses.prefix(5)) { savedVerse in
                                    Button(action: {
                                        // Haptic feedback
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                        
                                        print("📍 Navigating to saved verse: \(savedVerse.verseReference)")
                                        print("   Book: \(savedVerse.book), Chapter: \(savedVerse.chapter), Verse: \(savedVerse.verse)")
                                        
                                        // Navigate to the verse in Bible view
                                        bibleNavigator.open(
                                            book: savedVerse.book,
                                            chapter: savedVerse.chapter,
                                            verse: savedVerse.verse
                                        )
                                        
                                        print("   pendingSelection set to: \(bibleNavigator.pendingSelection?.book ?? -1):\(bibleNavigator.pendingSelection?.chapter ?? -1):\(bibleNavigator.pendingSelection?.verse ?? -1)")
                                        
                                        // Dismiss profile view after a brief delay to ensure navigation is set
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            dismiss()
                                        }
                                    }) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            // Verse reference with translation
                                            HStack(spacing: 8) {
                                                Image(systemName: "heart.fill")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(StyleGuide.gold)
                                                
                                                Text(savedVerse.verseReference)
                                                    .font(StyleGuide.merriweather(size: 14, weight: .bold))
                                                    .foregroundColor(StyleGuide.mainBrown)
                                                
                                                Spacer()
                                                
                                                if let translation = savedVerse.translation {
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
                                                
                                                // Chevron indicator
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.25))
                                            }
                                            
                                            // Verse text
                                            Text(savedVerse.verse_text)
                                                .font(StyleGuide.merriweather(size: 13, weight: .regular))
                                                .foregroundColor(StyleGuide.mainBrown.opacity(0.75))
                                                .lineLimit(3)
                                                .lineSpacing(3)
                                                .multilineTextAlignment(.leading)
                                            
                                            // Date
                                            Text(savedVerse.relativeDate)
                                                .font(StyleGuide.merriweather(size: 11, weight: .medium))
                                                .foregroundColor(StyleGuide.mainBrown.opacity(0.45))
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
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            Task {
                                                do {
                                                    try await userDataManager.unsaveVerse(
                                                        book: savedVerse.book,
                                                        chapter: savedVerse.chapter,
                                                        verse: savedVerse.verse,
                                                        translation: savedVerse.translation
                                                    )
                                                } catch {
                                                    print("❌ Error unsaving verse: \(error)")
                                                }
                                            }
                                        } label: {
                                            Label("Remove from Saved", systemImage: "heart.slash")
                                        }
                                    }
                                }
                                
                                // "View All" button if more than 5 saved verses
                                if userDataManager.savedVerses.count > 5 {
                                    Button(action: {
                                        // TODO: Navigate to all saved verses view
                                    }) {
                                        HStack {
                                            Image(systemName: "heart.text.square")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(StyleGuide.gold)
                                            
                                            Text("View All (\(userDataManager.savedVerses.count) verses)")
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
                            
                            // Divider
                            Rectangle()
                                .fill(StyleGuide.mainBrown.opacity(0.1))
                                .frame(height: 1)
                                .padding(.horizontal, StyleGuide.spacing.lg)
                            
                            // Delete Account Button
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.red.opacity(0.7))
                                    
                                    Text("Delete Account")
                                        .font(StyleGuide.merriweather(size: 16, weight: .medium))
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.red.opacity(0.3))
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
                    
                    // Bottom spacing to ensure content isn't cut off
                    Spacer()
                        .frame(height: 100)
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
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(
                userDataManager: userDataManager,
                authManager: authManager
            )
        }
        .sheet(item: $showBadgeDetail) { badge in
            BadgeDetailView(
                badge: badge,
                isEarned: displayStreak >= badge.daysRequired,
                currentStreak: displayStreak
            )
        }
        .fullScreenCover(item: $celebratingBadge) { badge in
            BadgeCelebrationView(
                badge: badge,
                onDismiss: {
                    celebratingBadge = nil
                }
            )
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone. All your data, including notes, saved verses, and progress will be permanently deleted.")
        }
        .overlay {
            if isDeletingAccount {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Deleting account...")
                            .font(StyleGuide.merriweather(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(StyleGuide.mainBrown)
                    )
                }
            }
        }
    }
    
    // MARK: - Delete Account
    private func deleteAccount() async {
        isDeletingAccount = true
        
        do {
            // Delete user data from database
            try await userDataManager.deleteAccount()
            
            // Sign out and delete auth account
            await authManager.deleteAccount()
            
            await MainActor.run {
                isDeletingAccount = false
            }
        } catch {
            await MainActor.run {
                isDeletingAccount = false
                print("❌ Error deleting account: \(error)")
                // Show error to user
                // You might want to add an error state here
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

// MARK: - Badge Configuration
struct StreakBadge: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let daysRequired: Int
    let assetName: String // Base name without "Unfilled" suffix
    let description: String
    let celebrationMessage: String
    
    static let allBadges: [StreakBadge] = [
        StreakBadge(
            name: "Spark",
            daysRequired: 2,
            assetName: "badgeSpark",
            description: "Your faith journey begins with a spark",
            celebrationMessage: "You've kindled your first spark! Two days of consistent devotion."
        ),
        StreakBadge(
            name: "Ember",
            daysRequired: 7,
            assetName: "badgeEmber",
            description: "A full week of dedication",
            celebrationMessage: "The ember glows! Seven days of faithful commitment."
        ),
        StreakBadge(
            name: "Flame",
            daysRequired: 14,
            assetName: "badgeFlame",
            description: "Two weeks of unwavering devotion",
            celebrationMessage: "Your flame burns bright! Fourteen days of spiritual growth."
        ),
        StreakBadge(
            name: "Lantern",
            daysRequired: 30,
            assetName: "badgeLantern",
            description: "A full month lighting your path",
            celebrationMessage: "Your lantern shines! Thirty days of steadfast faith."
        ),
        StreakBadge(
            name: "Beacon",
            daysRequired: 60,
            assetName: "badgeBeacon",
            description: "Two months guiding others",
            celebrationMessage: "You're a beacon of light! Sixty days of inspiration."
        ),
        StreakBadge(
            name: "Lighthouse",
            daysRequired: 100,
            assetName: "badgeLighthouse",
            description: "A hundred days standing strong",
            celebrationMessage: "Standing tall like a lighthouse! One hundred days of devotion."
        ),
        StreakBadge(
            name: "Steadfast",
            daysRequired: 200,
            assetName: "badgeSteadfast",
            description: "Unwavering for two hundred days",
            celebrationMessage: "Steadfast and true! Two hundred days of faithful dedication."
        ),
        StreakBadge(
            name: "Year of Light",
            daysRequired: 365,
            assetName: "badgeYear",
            description: "A full year of daily devotion",
            celebrationMessage: "A complete Year of Light! 365 days of unwavering faith. You are an inspiration!"
        )
    ]
}

// MARK: - Badge Item
struct BadgeItem: View {
    let badge: StreakBadge
    let isEarned: Bool
    let currentStreak: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Badge Image
            Image(isEarned ? badge.assetName : "\(badge.assetName)Unfilled")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .opacity(isEarned ? 1.0 : 0.5)
            
            // Badge Title
            Text(badge.name)
                .font(StyleGuide.merriweather(size: 10, weight: .medium))
                .foregroundColor(isEarned ? StyleGuide.mainBrown : StyleGuide.mainBrown.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            // Days Required
            Text(isEarned ? "✓ \(badge.daysRequired)" : "\(badge.daysRequired) days")
                .font(StyleGuide.merriweather(size: 8, weight: isEarned ? .semibold : .regular))
                .foregroundColor(isEarned ? StyleGuide.gold : StyleGuide.mainBrown.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Badge Item with Progress Ring
struct BadgeItemWithProgress: View {
    let badge: StreakBadge
    let isEarned: Bool
    let currentStreak: Int
    let isNextBadge: Bool
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            // Badge Image with Progress Ring
            ZStack {
                // Progress ring (only show for next badge)
                if isNextBadge && !isEarned {
                    Circle()
                        .stroke(StyleGuide.mainBrown.opacity(0.1), lineWidth: 3)
                        .frame(width: 78, height: 78)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [StyleGuide.gold, StyleGuide.gold.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 78, height: 78)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
                
                // Badge Image
                Image(isEarned ? badge.assetName : "\(badge.assetName)Unfilled")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .opacity(isEarned ? 1.0 : (isNextBadge ? 0.8 : 0.5))
                    .shadow(
                        color: isEarned ? StyleGuide.gold.opacity(0.4) : .clear,
                        radius: isEarned ? 8 : 0,
                        x: 0,
                        y: isEarned ? 4 : 0
                    )
            }
            .scaleEffect(isEarned ? 1.05 : 1.0)
            
            // Badge Title
            Text(badge.name)
                .font(StyleGuide.merriweather(size: 10, weight: isEarned ? .semibold : .medium))
                .foregroundColor(isEarned ? StyleGuide.mainBrown : (isNextBadge ? StyleGuide.mainBrown.opacity(0.7) : StyleGuide.mainBrown.opacity(0.4)))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            // Days Required / Progress
            if isNextBadge && !isEarned {
                Text("\(currentStreak)/\(badge.daysRequired)")
                    .font(StyleGuide.merriweather(size: 8, weight: .semibold))
                    .foregroundColor(StyleGuide.gold)
            } else {
                Text(isEarned ? "✓ \(badge.daysRequired)" : "\(badge.daysRequired) days")
                    .font(StyleGuide.merriweather(size: 8, weight: isEarned ? .semibold : .regular))
                    .foregroundColor(isEarned ? StyleGuide.gold : StyleGuide.mainBrown.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Badge Detail View
struct BadgeDetailView: View {
    let badge: StreakBadge
    let isEarned: Bool
    let currentStreak: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                StyleGuide.backgroundBeige
                    .ignoresSafeArea()
                
                VStack(spacing: StyleGuide.spacing.xl) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Badge Image
                    Image(isEarned ? badge.assetName : "\(badge.assetName)Unfilled")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .opacity(isEarned ? 1.0 : 0.5)
                    
                    // Badge Name
                    Text(badge.name)
                        .font(StyleGuide.merriweather(size: 32, weight: .bold))
                        .foregroundColor(StyleGuide.mainBrown)
                    
                    // Status
                    if isEarned {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                            
                            Text("Earned")
                                .font(StyleGuide.merriweather(size: 18, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    } else {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                                
                                Text("Locked")
                                    .font(StyleGuide.merriweather(size: 18, weight: .semibold))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                            }
                            
                            Text("\(badge.daysRequired - currentStreak) days to go")
                                .font(StyleGuide.merriweather(size: 14, weight: .medium))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                        }
                    }
                    
                    // Description
                    VStack(spacing: 12) {
                        Text(badge.description)
                            .font(StyleGuide.merriweather(size: 16, weight: .medium))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, StyleGuide.spacing.xl)
                        
                        // Requirement
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 16))
                                .foregroundColor(StyleGuide.gold)
                            
                            Text("\(badge.daysRequired) day streak required")
                                .font(StyleGuide.merriweather(size: 14, weight: .medium))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                        }
                        .padding(.horizontal, StyleGuide.spacing.lg)
                        .padding(.vertical, StyleGuide.spacing.md)
                        .background(StyleGuide.gold.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(StyleGuide.mainBrown)
                }
            }
        }
    }
}

// MARK: - Badge Celebration View
struct BadgeCelebrationView: View {
    let badge: StreakBadge
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            // Confetti
            if showConfetti {
                ConfettiView()
            }
            
            VStack(spacing: StyleGuide.spacing.xl) {
                Spacer()
                
                // Badge Earned!
                Text("Badge Earned!")
                    .font(StyleGuide.merriweather(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(opacity)
                
                // Badge Image with animation
                Image(badge.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220, height: 220)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                // Badge Name
                Text(badge.name)
                    .font(StyleGuide.merriweather(size: 36, weight: .bold))
                    .foregroundColor(StyleGuide.gold)
                    .opacity(opacity)
                
                // Celebration Message
                Text(badge.celebrationMessage)
                    .font(StyleGuide.merriweather(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, StyleGuide.spacing.xl)
                    .opacity(opacity)
                
                Spacer()
                
                // Continue Button
                Button(action: onDismiss) {
                    Text("Continue")
                        .font(StyleGuide.merriweather(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(StyleGuide.gold)
                        .cornerRadius(12)
                }
                .padding(.horizontal, StyleGuide.spacing.xl)
                .padding(.bottom, StyleGuide.spacing.xl)
                .opacity(opacity)
            }
        }
        .onAppear {
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1.0
            }
            
            // Show confetti after a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                ConfettiPiece(index: index)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    let index: Int
    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 1
    
    private let colors: [Color] = [
        StyleGuide.gold,
        .orange,
        .red,
        .pink,
        .purple,
        .blue,
        .green,
        .yellow
    ]
    
    var body: some View {
        Circle()
            .fill(colors[index % colors.count])
            .frame(width: CGFloat.random(in: 8...16), height: CGFloat.random(in: 8...16))
            .position(position)
            .opacity(opacity)
            .onAppear {
                let startX = CGFloat.random(in: 0...UIScreen.main.bounds.width)
                let startY = CGFloat.random(in: -100...0)
                position = CGPoint(x: startX, y: startY)
                
                // Animate downward
                withAnimation(
                    .easeIn(duration: Double.random(in: 2...4))
                    .delay(Double.random(in: 0...0.5))
                ) {
                    position = CGPoint(
                        x: startX + CGFloat.random(in: -100...100),
                        y: UIScreen.main.bounds.height + 100
                    )
                    opacity = 0
                }
            }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @ObservedObject var userDataManager: UserDataManager
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName: String = ""
    @State private var username: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showingSuccess: Bool = false
    @State private var usernameError: String? = nil
    @State private var isCheckingUsername: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                StyleGuide.backgroundBeige
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: StyleGuide.spacing.xl) {
                            Spacer()
                                .frame(height: 32)
                            
                            profileIcon
                            fieldsCard
                            statusMessages
                            
                            Spacer()
                                .frame(height: 100)
                        }
                    }
                    
                    saveButtonSection
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(StyleGuide.mainBrown)
                }
            }
            .onAppear {
                firstName = authManager.userFirstName ?? ""
                username = userDataManager.userProfile?.username ?? ""
            }
        }
    }
    
    // MARK: - View Components
    
    private var profileIcon: some View {
        ZStack {
            Circle()
                .fill(StyleGuide.gold.opacity(0.2))
                .frame(width: 80, height: 80)
            
            Image(systemName: "person.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(StyleGuide.gold)
        }
    }
    
    private var fieldsCard: some View {
        VStack(spacing: StyleGuide.spacing.xl) {
            firstNameField
            
            Rectangle()
                .fill(StyleGuide.mainBrown.opacity(0.1))
                .frame(height: 1)
                .padding(.vertical, 4)
            
            usernameField
        }
        .padding(StyleGuide.spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(StyleGuide.gold.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        .padding(.horizontal, StyleGuide.spacing.xl)
    }
    
    private var firstNameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("First Name")
                .font(StyleGuide.merriweather(size: 13, weight: .semibold))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                .textCase(.uppercase)
                .tracking(0.5)
            
            TextField("Enter your first name", text: $firstName)
                .font(StyleGuide.merriweather(size: 17, weight: .regular))
                .foregroundColor(StyleGuide.mainBrown)
                .padding(StyleGuide.spacing.md + 2)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(StyleGuide.gold.opacity(0.3), lineWidth: 1.5)
                )
            
            Text("This is how we'll greet you in the app")
                .font(StyleGuide.merriweather(size: 12, weight: .regular))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                .padding(.leading, 2)
        }
    }
    
    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Username")
                .font(StyleGuide.merriweather(size: 13, weight: .semibold))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                .textCase(.uppercase)
                .tracking(0.5)
            
            usernameInput
            usernameHelperText
        }
    }
    
    private var usernameInput: some View {
        HStack(spacing: 12) {
            TextField("Enter your username", text: $username)
                .font(StyleGuide.merriweather(size: 17, weight: .regular))
                .foregroundColor(StyleGuide.mainBrown)
                .autocapitalization(.none)
                .onChange(of: username) { newValue in
                    username = newValue.lowercased()
                        .filter { $0.isLetter || $0.isNumber || $0 == "." || $0 == "_" }
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        await checkUsernameAvailability()
                    }
                }
            
            usernameStatusIcon
        }
        .padding(StyleGuide.spacing.md + 2)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(usernameError != nil ? Color.red.opacity(0.6) : StyleGuide.gold.opacity(0.3), lineWidth: 1.5)
        )
    }
    
    @ViewBuilder
    private var usernameStatusIcon: some View {
        Group {
            if isCheckingUsername {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: StyleGuide.gold))
                    .scaleEffect(0.9)
            } else if usernameError != nil {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red.opacity(0.8))
            } else if !username.isEmpty && username != (userDataManager.userProfile?.username ?? "") {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
        }
        .frame(width: 24, height: 24)
    }
    
    @ViewBuilder
    private var usernameHelperText: some View {
        if let error = usernameError {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 12))
                Text(error)
                    .font(StyleGuide.merriweather(size: 12, weight: .medium))
            }
            .foregroundColor(.red.opacity(0.8))
            .padding(.leading, 2)
        } else {
            Text("Your unique identifier for connecting with friends")
                .font(StyleGuide.merriweather(size: 12, weight: .regular))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                .padding(.leading, 2)
        }
    }
    
    @ViewBuilder
    private var statusMessages: some View {
        if let error = errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(error)
                    .font(StyleGuide.merriweather(size: 14, weight: .medium))
            }
            .foregroundColor(.red.opacity(0.8))
            .padding(StyleGuide.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
            )
            .padding(.horizontal, StyleGuide.spacing.xl)
        }
        
        if showingSuccess {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("Profile updated successfully!")
                    .font(StyleGuide.merriweather(size: 14, weight: .medium))
            }
            .foregroundColor(.green)
            .padding(StyleGuide.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
            )
            .padding(.horizontal, StyleGuide.spacing.xl)
        }
    }
    
    private var saveButtonSection: some View {
        VStack(spacing: 0) {
            LinearGradient(
                gradient: Gradient(colors: [
                    StyleGuide.backgroundBeige.opacity(0),
                    StyleGuide.backgroundBeige
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            
            Button(action: {
                Task {
                    await saveProfile()
                }
            }) {
                if isSaving {
                    HStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Saving...")
                    }
                } else {
                    Text("Save Changes")
                }
            }
            .primaryButtonStyle()
            .disabled(isSaving || usernameError != nil || firstName.isEmpty || username.isEmpty)
            .opacity((isSaving || usernameError != nil || firstName.isEmpty || username.isEmpty) ? 0.5 : 1.0)
            .padding(.horizontal, StyleGuide.spacing.xl)
            .padding(.bottom, StyleGuide.spacing.xl)
            .background(StyleGuide.backgroundBeige)
        }
    }
    
    private func checkUsernameAvailability() async {
        guard !username.isEmpty else {
            usernameError = nil
            return
        }
        
        // Don't check if it's the user's current username
        if username == userDataManager.userProfile?.username {
            usernameError = nil
            return
        }
        
        // Basic validation
        if username.count < 3 {
            usernameError = "Username must be at least 3 characters"
            return
        }
        
        isCheckingUsername = true
        usernameError = nil
        
        // Check if username is available
        let isAvailable = await userDataManager.isUsernameAvailable(username)
        
        await MainActor.run {
            isCheckingUsername = false
            if !isAvailable {
                usernameError = "Username is already taken"
            }
        }
    }
    
    private func saveProfile() async {
        isSaving = true
        errorMessage = nil
        showingSuccess = false
        
        do {
            // Update first name
            authManager.userFirstName = firstName
            UserDefaults.standard.set(firstName, forKey: "userFirstName")
            
            // Update username in database
            try await userDataManager.updateProfile(username: username, firstName: firstName)
            
            await MainActor.run {
                isSaving = false
                showingSuccess = true
                
                // Dismiss after brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = "Failed to update profile. Please try again."
                print("❌ Error updating profile: \(error)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(userDataManager: UserDataManager(supabase: AuthManager().supabase, authManager: AuthManager()))
            .environmentObject(AuthManager())
    }
}

