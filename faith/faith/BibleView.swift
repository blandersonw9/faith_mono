import SwiftUI
import Supabase
import UIKit

// MARK: - Reading Mode
enum ReadingMode: String, CaseIterable {
    case day = "Day"
    case night = "Night"
    case sepia = "Sepia"
    
    var icon: String {
        switch self {
        case .day: return "sun.max.fill"
        case .night: return "moon.fill"
        case .sepia: return "book.fill"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .day: return StyleGuide.backgroundBeige
        case .night: return Color(red: 0.12, green: 0.12, blue: 0.14)
        case .sepia: return Color(red: 0.95, green: 0.91, blue: 0.84)
        }
    }
    
    var textColor: Color {
        switch self {
        case .day: return StyleGuide.mainBrown
        case .night: return Color(red: 0.9, green: 0.88, blue: 0.82)
        case .sepia: return Color(red: 0.35, green: 0.28, blue: 0.22)
        }
    }
    
    var cardBackground: Color {
        switch self {
        case .day: return StyleGuide.backgroundBeige
        case .night: return Color(red: 0.16, green: 0.16, blue: 0.18)
        case .sepia: return Color(red: 0.96, green: 0.93, blue: 0.87)
        }
    }
    
    var shadowLight: Color {
        switch self {
        case .day: return Color.white.opacity(0.8)
        case .night: return Color.white.opacity(0.03)
        case .sepia: return Color.white.opacity(0.7)
        }
    }
    
    var shadowDark: Color {
        switch self {
        case .day: return Color.black.opacity(0.15)
        case .night: return Color.black.opacity(0.5)
        case .sepia: return Color.black.opacity(0.12)
        }
    }
}

struct BibleView: View {
    @EnvironmentObject var bibleNavigator: BibleNavigator
    @StateObject private var bibleManager = BibleManager()
    @State private var showingBookPicker = false
    @State private var targetVerse: Int? = nil
    @State private var scrollTrigger: Bool = false
    @State private var selectedVerseId: Int? = nil
    @State private var showActionMenu: Bool = false
    @State private var actionMenuSize: CGSize = .zero
    @State private var verseHighlights: [Int: Color] = [:] // Track verse highlight colors
    @State private var fontSize: CGFloat = UserDefaults.standard.object(forKey: "bibleTextSize") as? CGFloat ?? 16
    @State private var readingMode: ReadingMode = {
        if let savedMode = UserDefaults.standard.string(forKey: "bibleReadingMode"),
           let mode = ReadingMode(rawValue: savedMode) {
            return mode
        }
        return .day
    }()
    @State private var showSettingsMenu = false
    @State private var showNavigationArrows = true
    @State private var lastScrollOffset: CGFloat = 0
    @State private var isAtBottom = false
    
    // Font size constants
    private let minFontSize: CGFloat = 12
    private let maxFontSize: CGFloat = 24
    private let fontSizeStep: CGFloat = 1
    
    
    // MARK: - Helper Functions
    
    private func cleanBibleText(_ text: String) -> String {
        var cleanedText = text
        
        // Convert [word] to italics formatting
        cleanedText = cleanedText.replacingOccurrences(of: "\\[([^\\]]+)\\]", with: "*$1*", options: .regularExpression)
        
        // Remove paragraph indicators (¶, pilcrow symbols)
        cleanedText = cleanedText.replacingOccurrences(of: "¶", with: "")
        
        // Convert guillemets/angle quotes to standard typographic quotes
        cleanedText = cleanedText.replacingOccurrences(of: "‹", with: "“")
        cleanedText = cleanedText.replacingOccurrences(of: "›", with: "”")
        cleanedText = cleanedText.replacingOccurrences(of: "«", with: "“")
        cleanedText = cleanedText.replacingOccurrences(of: "»", with: "”")
        
        // Remove other common Bible formatting markers (but keep [word] as italics)
        cleanedText = cleanedText.replacingOccurrences(of: "\\{[^}]*\\}", with: "", options: .regularExpression) // {word}
        cleanedText = cleanedText.replacingOccurrences(of: "\\([^)]*\\)", with: "", options: .regularExpression) // (word)
        
        // Clean up extra whitespace and normalize
        cleanedText = cleanedText.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedText
    }
    
    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding = geometry.size.width * 0.05
            
            VStack(spacing: 0) {
                // Header with combined book/chapter selector - moved to top left
                if showNavigationArrows {
                HStack {
                    Button(action: {
                        showingBookPicker = true
                    }) {
                    HStack {
                        Text(bibleManager.currentBook > 0 ? 
                             "\(BibleManager.bookNames[bibleManager.currentBook] ?? "Select Book") \(bibleManager.currentChapter)" : 
                             "Select Book")
                            .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                            .foregroundColor(readingMode.textColor)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(readingMode.textColor)
                    }
                    .padding(.horizontal, StyleGuide.spacing.md)
                    .padding(.vertical, StyleGuide.spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: StyleGuide.cornerRadius.sm, style: .continuous)
                            .fill(readingMode.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: StyleGuide.cornerRadius.sm, style: .continuous)
                            .stroke(readingMode.textColor.opacity(0.06), lineWidth: 0.8)
                    )
                    .shadow(color: readingMode.shadowLight, radius: 2, x: -2, y: -2)
                    .shadow(color: readingMode.shadowDark, radius: 3, x: 2, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    // Settings menu button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showSettingsMenu.toggle()
                        }
                    }) {
                        Image(systemName: showSettingsMenu ? "xmark" : "textformat.size")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(readingMode.textColor)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(readingMode.cardBackground)
                            )
                            .overlay(
                                Circle()
                                    .stroke(readingMode.textColor.opacity(0.06), lineWidth: 0.8)
                            )
                            .shadow(color: readingMode.shadowLight, radius: 2, x: -2, y: -2)
                            .shadow(color: readingMode.shadowDark, radius: 3, x: 2, y: 2)
                            .rotationEffect(.degrees(showSettingsMenu ? 0 : 0))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, StyleGuide.spacing.lg)
                .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Settings dropdown menu
                if showSettingsMenu {
                    ReadingSettingsMenu(
                        fontSize: $fontSize,
                        readingMode: $readingMode,
                        minFontSize: minFontSize,
                        maxFontSize: maxFontSize,
                        fontSizeStep: fontSizeStep,
                        onDismiss: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showSettingsMenu = false
                            }
                        }
                    )
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, StyleGuide.spacing.sm)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
                }
            
            // Bible content
            ScrollViewReader { scrollProxy in
            ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Content starts here
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
                            .padding(.horizontal, horizontalPadding)
                    } else {
                        ForEach(bibleManager.verses, id: \.id) { verse in
                            let isSelected = selectedVerseId == verse.id
                            let highlightColor = verseHighlights[verse.id]
                            ZStack(alignment: .bottomLeading) {
                                // Highlight background for colored verses (when not selected)
                                if let color = highlightColor, !isSelected {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(color.opacity(0.4))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .stroke(color.opacity(0.3), lineWidth: 1)
                                        )
                                        .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
                                        .padding(.horizontal, horizontalPadding - 4)
                                        .padding(.vertical, StyleGuide.spacing.xs)
                                        .allowsHitTesting(false)
                                }
                                
                                // Enhanced card behind the selected verse (with highlight color if present)
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: highlightColor != nil ? [
                                                    highlightColor!.opacity(0.5),
                                                    highlightColor!.opacity(0.6),
                                                    highlightColor!.opacity(0.55)
                                                ] : [
                                                    readingMode.shadowLight.opacity(0.15),
                                                    readingMode.cardBackground.opacity(0.95),
                                                    readingMode.cardBackground.opacity(0.9)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: highlightColor != nil ? [
                                                            highlightColor!.opacity(0.6),
                                                            highlightColor!.opacity(0.4),
                                                            highlightColor!.opacity(0.35)
                                                        ] : [
                                                            readingMode.shadowLight.opacity(0.8),
                                                            readingMode.textColor.opacity(0.12),
                                                            readingMode.textColor.opacity(0.08)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1.2
                                                )
                                        )
                                        // Primary light shadow (strong highlight)
                                        .shadow(color: readingMode.shadowLight, radius: 4, x: -4, y: -4)
                                        // Secondary light shadow (soft glow)
                                        .shadow(color: readingMode.shadowLight.opacity(0.7), radius: 2, x: -2, y: -2)
                                        // Primary dark shadow (depth) - use highlight color if present
                                        .shadow(color: (highlightColor ?? readingMode.shadowDark), radius: 8, x: 5, y: 5)
                                        // Secondary dark shadow (definition)
                                        .shadow(color: (highlightColor ?? readingMode.shadowDark).opacity(0.5), radius: 3, x: 2, y: 2)
                                        // Inner highlight
                                        .shadow(color: readingMode.shadowLight.opacity(0.5), radius: 1, x: -1, y: -1)
                                        .padding(.horizontal, horizontalPadding - 4)
                                        .padding(.vertical, StyleGuide.spacing.xs)
                                        .allowsHitTesting(false)
                                }

                                // Verse row content
                                HStack(alignment: .top, spacing: StyleGuide.spacing.sm) {
                                    // Minimal verse number
                                    Text("\(verse.verse)")
                                        .font(StyleGuide.merriweather(size: max(10, fontSize * 0.625), weight: .semibold))
                                        .foregroundColor(readingMode.textColor.opacity(0.5))
                                        .frame(width: max(24, fontSize * 1.5), alignment: .trailing)
                                    
                                    Text(LocalizedStringKey(cleanBibleText(verse.text)))
                                        .font(StyleGuide.merriweather(size: fontSize, weight: isSelected ? .medium : .regular))
                                        .foregroundColor(isSelected ? readingMode.textColor.opacity(0.95) : readingMode.textColor)
                                        .lineSpacing(fontSize * 0.375)
                                        .multilineTextAlignment(.leading)
                                        .shadow(color: isSelected ? readingMode.shadowLight.opacity(0.5) : Color.clear, radius: 0.5, x: 0, y: 0.5)
                                }
                                .padding(.horizontal, horizontalPadding + 4)
                                .padding(.vertical, StyleGuide.spacing.sm)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // Haptic feedback for verse selection
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    
                                    // More responsive spring animation with gentle bounce
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1)) {
                                        if selectedVerseId == verse.id {
                                            // If same verse is tapped again, deselect it
                                            selectedVerseId = nil
                                            showActionMenu = false
                                        } else {
                                            // If different verse is tapped, select it and show menu
                                            selectedVerseId = verse.id
                                            showActionMenu = true
                                        }
                                    }
                                }
                                .anchorPreference(key: VerseBoundsPreferenceKey.self, value: .bounds) { anchor in
                                    isSelected ? [verse.id: anchor] : [:]
                                }
                            }
                            .scaleEffect(isSelected ? 1.02 : 1.0)
                            .compositingGroup()
                            .id(verse.id)
                            .zIndex(isSelected ? 100 : 0)
                        }
                        
                        // Add bottom padding for better spacing
                        Spacer()
                            .frame(height: 120)
                        
                        // Bottom detection
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: BottomDetectionPreferenceKey.self,
                                value: geometry.frame(in: .named("bibleScroll")).maxY
                            )
                        }
                        .frame(height: 1)
                    }
                }
                .padding(.top, StyleGuide.spacing.md)
            }
            .coordinateSpace(name: "bibleScroll")
            .onPreferenceChange(BottomDetectionPreferenceKey.self) { maxY in
                // Check if we're near the bottom
                // When scrolled to bottom, the bottom element's maxY is visible in viewport
                // We check if it's within reasonable viewport bounds (positive and less than screen height + buffer)
                let isNearBottom = maxY > 0 && maxY < 1000
                
                // Update bottom state
                let wasAtBottom = isAtBottom
                isAtBottom = isNearBottom
                
                // Show arrows when reaching bottom
                if isNearBottom && !showNavigationArrows && !wasAtBottom {
                    // Haptic feedback when arrows auto-appear at bottom
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showNavigationArrows = true
                    }
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        let velocity = value.translation.height
                        if abs(velocity) > 10 {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if velocity < 0 {
                                    // Dragging up = scrolling down
                                    // Don't hide if we're at the bottom
                                    if !isAtBottom {
                                        showNavigationArrows = false
                                    }
                                    showSettingsMenu = false // Close settings menu when scrolling
                                } else {
                                    // Dragging down = scrolling up
                                    showNavigationArrows = true
                                }
                            }
                        }
                    }
            )
            
            // Floating menu overlay positioned using anchor preference so it follows scroll
            .overlayPreferenceValue(VerseBoundsPreferenceKey.self) { preferences in
                GeometryReader { proxy in
                    if showActionMenu,
                       let id = selectedVerseId,
                       let verse = bibleManager.verses.first(where: { $0.id == id }),
                       let anchor = preferences[id] {
                        let rect = proxy[anchor]
                        // Compute y position: prefer below; use a larger gap when above
                        let spacingBelow = StyleGuide.spacing.md
                        let spacingAbove = StyleGuide.spacing.lg
                        let extraAboveGap = StyleGuide.spacing.md
                        let menuHeight = max(actionMenuSize.height, 260)
                        let containerHeight = proxy.size.height
                        let yBelow = rect.maxY + spacingBelow
                        let yAbove = rect.minY - (spacingAbove + extraAboveGap) - menuHeight
                        let preferredY = (yBelow + menuHeight > containerHeight - 8) ? max(spacingAbove, yAbove) : yBelow
                        // Position menu using top-left offset
                        VerseActionMenu(
                            currentHighlightColor: verseHighlights[verse.id],
                            copyAction: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                let ref = "\(BibleManager.bookNames[verse.book] ?? "") \(verse.chapter):\(verse.verse)"
                                let text = cleanBibleText(verse.text)
                                UIPasteboard.general.string = "\(ref) — \(text)"
                                withAnimation { showActionMenu = false }
                            },
                            interpretAction: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                let ref = "\(BibleManager.bookNames[verse.book] ?? "") \(verse.chapter):\(verse.verse)"
                                let text = cleanBibleText(verse.text)
                                let prompt = "Interpret this verse: \n\n\(ref)\n\n\"\(text)\""
                                NotificationCenter.default.post(name: .openChatWithPrompt, object: prompt)
                                withAnimation { showActionMenu = false }
                            },
                            shareAction: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                let ref = "\(BibleManager.bookNames[verse.book] ?? "") \(verse.chapter):\(verse.verse)"
                                let text = cleanBibleText(verse.text)
                                let shareText = "\(ref)\n\n\"\(text)\""
                                let activityVC = UIActivityViewController(
                                    activityItems: [shareText],
                                    applicationActivities: nil
                                )
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootVC = windowScene.windows.first?.rootViewController {
                                    activityVC.popoverPresentationController?.sourceView = rootVC.view
                                    activityVC.popoverPresentationController?.sourceRect = CGRect(
                                        x: rootVC.view.bounds.midX,
                                        y: rootVC.view.bounds.midY,
                                        width: 0,
                                        height: 0
                                    )
                                    rootVC.present(activityVC, animated: true)
                                }
                                withAnimation { showActionMenu = false }
                            },
                            saveAction: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                print("Save verse: \(verse.book):\(verse.chapter):\(verse.verse)")
                                withAnimation { showActionMenu = false }
                            },
                            noteAction: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                print("Add note to verse: \(verse.book):\(verse.chapter):\(verse.verse)")
                                withAnimation { showActionMenu = false }
                            },
                            colorAction: { color in
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if color == .white {
                                        // White color removes the highlight
                                        verseHighlights.removeValue(forKey: verse.id)
                                    } else {
                                        // Other colors set the highlight
                                        verseHighlights[verse.id] = color
                                    }
                                }
                            }
                        )
                        .background(
                            GeometryReader { g in
                                Color.clear.preference(key: ActionMenuSizePreferenceKey.self, value: g.size)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .offset(x: horizontalPadding + 4, y: preferredY)
                        .zIndex(1001)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.85).combined(with: .opacity),
                                removal: .scale(scale: 0.9).combined(with: .opacity)
                            )
                        )
                    }
                }
            }
            .onPreferenceChange(ActionMenuSizePreferenceKey.self) { newSize in
                actionMenuSize = newSize
            }
            
            // Chapter Navigation at the bottom
            if showNavigationArrows {
                ChapterNavigationBar(
                    bibleManager: bibleManager,
                    readingMode: readingMode
                )
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 60) // Lift above nav bar
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            } // end ZStack
            .animation(.easeInOut(duration: 0.3), value: showNavigationArrows)
            .onChange(of: bibleManager.currentChapter) { _ in
                // Scroll to target verse if set, otherwise scroll to top of chapter
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let v = targetVerse, let target = bibleManager.verses.first(where: { $0.verse == v }) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            scrollProxy.scrollTo(target.id, anchor: .top)
                        }
                        targetVerse = nil // Clear target verse after scrolling
                    } else if let firstVerse = bibleManager.verses.first {
                        // No target verse, scroll to first verse of chapter
                        withAnimation(.easeOut(duration: 0.25)) {
                            scrollProxy.scrollTo(firstVerse.id, anchor: .top)
                        }
                    }
                }
            }
            .onChange(of: scrollTrigger) { _ in
                if let v = targetVerse, let target = bibleManager.verses.first(where: { $0.verse == v }) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            scrollProxy.scrollTo(target.id, anchor: .top)
                        }
                    }
                }
            }
            }
            }
        }
        .background(readingMode.backgroundColor.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.4), value: readingMode)
        .animation(.easeInOut(duration: 0.3), value: showNavigationArrows)
        .onAppear {
            // Apply pending selection if any
            if let sel = bibleNavigator.pendingSelection {
                targetVerse = sel.verse
                bibleManager.loadVerses(book: sel.book, chapter: sel.chapter)
                bibleNavigator.pendingSelection = nil
            } else {
                // Load saved position or default to Genesis 1
                let savedBook = UserDefaults.standard.integer(forKey: "savedBibleBook")
                let savedChapter = UserDefaults.standard.integer(forKey: "savedBibleChapter")
                let savedVerse = UserDefaults.standard.integer(forKey: "savedBibleVerse")
                if savedBook > 0 && savedChapter > 0 {
                    targetVerse = savedVerse > 0 ? savedVerse : nil
                    bibleManager.loadVerses(book: savedBook, chapter: savedChapter)
                } else if bibleManager.verses.isEmpty {
                    targetVerse = nil
                    bibleManager.loadVerses(book: 1, chapter: 1)
                }
            }
        }
        .onChange(of: bibleNavigator.pendingSelection) { newValue in
            guard let sel = newValue else { return }
            targetVerse = sel.verse
            bibleManager.loadVerses(book: sel.book, chapter: sel.chapter)
            bibleNavigator.pendingSelection = nil
        }
        .onChange(of: bibleManager.currentBook) { newBook in
            UserDefaults.standard.set(newBook, forKey: "savedBibleBook")
        }
        .onChange(of: bibleManager.currentChapter) { newChapter in
            UserDefaults.standard.set(newChapter, forKey: "savedBibleChapter")
            if let v = targetVerse, v > 0 {
                UserDefaults.standard.set(v, forKey: "savedBibleVerse")
            } else {
                UserDefaults.standard.removeObject(forKey: "savedBibleVerse")
            }
            // Reset verse selection and menu when chapter changes
            selectedVerseId = nil
            showActionMenu = false
            isAtBottom = false
            // Show navigation arrows when chapter changes
            withAnimation(.easeInOut(duration: 0.3)) {
                showNavigationArrows = true
            }
        }
        .onChange(of: readingMode) { newMode in
            UserDefaults.standard.set(newMode.rawValue, forKey: "bibleReadingMode")
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToBibleTab)) { _ in
            let savedBook = UserDefaults.standard.integer(forKey: "savedBibleBook")
            let savedChapter = UserDefaults.standard.integer(forKey: "savedBibleChapter")
            let savedVerse = UserDefaults.standard.integer(forKey: "savedBibleVerse")
            if savedBook > 0 && savedChapter > 0 {
                targetVerse = savedVerse > 0 ? savedVerse : nil
                bibleManager.loadVerses(book: savedBook, chapter: savedChapter)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    scrollTrigger.toggle()
                }
            }
        }
        .sheet(isPresented: $showingBookPicker) {
            BookPickerView(bibleManager: bibleManager)
        }
        .onTapGesture {
            // Tapping outside hides menus and deselects the verse
            if showActionMenu || selectedVerseId != nil || showSettingsMenu {
                withAnimation(.easeInOut(duration: 0.2)) { 
                    showActionMenu = false 
                    selectedVerseId = nil
                    showSettingsMenu = false
                }
            }
        }
    }
}

// MARK: - Book Picker
struct BookPickerView: View {
    @ObservedObject var bibleManager: BibleManager
    @Environment(\.presentationMode) var presentationMode
    @State private var expandedBook: Int? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(bibleManager.getAvailableBooks(), id: \.id) { book in
                    VStack(alignment: .leading, spacing: 0) {
                        // Book name button
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            if expandedBook == book.id {
                                expandedBook = nil
                            } else {
                                expandedBook = book.id
                            }
                        }) {
                            HStack {
                                Text(book.name)
                                    .font(StyleGuide.merriweather(size: 16, weight: .medium))
                                    .foregroundColor(StyleGuide.mainBrown)
                                
                                Spacer()
                                
                                Image(systemName: expandedBook == book.id ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(StyleGuide.mainBrown)
                            }
                            .padding(.horizontal, StyleGuide.spacing.lg)
                            .padding(.vertical, StyleGuide.spacing.md)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Chapters grid
                        if expandedBook == book.id {
                            VStack(spacing: StyleGuide.spacing.sm) {
                                ForEach(0..<(bibleManager.getAvailableChapters(for: book.id).count + 4) / 5, id: \.self) { row in
                                    HStack(spacing: 4) {
                                        ForEach(0..<5, id: \.self) { col in
                                            let chapterIndex = row * 5 + col
                                            if chapterIndex < bibleManager.getAvailableChapters(for: book.id).count {
                                                let chapter = bibleManager.getAvailableChapters(for: book.id)[chapterIndex]
                                                Button(action: {
                                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                                    impactFeedback.impactOccurred()
                                                    print("Selected: Book \(book.id), Chapter \(chapter)")
                                                    bibleManager.loadVerses(book: book.id, chapter: chapter)
                                                    presentationMode.wrappedValue.dismiss()
                                                }) {
                                                    Text("\(chapter)")
                                                        .font(StyleGuide.merriweather(size: 14, weight: .medium))
                                                        .foregroundColor(StyleGuide.mainBrown)
                                                        .frame(maxWidth: .infinity)
                                                        .frame(height: 44)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                                .fill(
                                                                    LinearGradient(
                                                                        colors: [
                                                                            StyleGuide.backgroundBeige.opacity(0.9),
                                                                            StyleGuide.backgroundBeige.opacity(0.95)
                                                                        ],
                                                                        startPoint: .topLeading,
                                                                        endPoint: .bottomTrailing
                                                                    )
                                                                )
                                                        )
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                                .stroke(
                                                                    LinearGradient(
                                                                        colors: [
                                                                            Color.white.opacity(0.3),
                                                                            StyleGuide.mainBrown.opacity(0.08)
                                                                        ],
                                                                        startPoint: .topLeading,
                                                                        endPoint: .bottomTrailing
                                                                    ),
                                                                    lineWidth: 0.8
                                                                )
                                                        )
                                                        .cornerRadius(10)
                                                        // Light shadow (highlight)
                                                        .shadow(color: Color.white.opacity(0.8), radius: 2, x: -2, y: -2)
                                                        // Dark shadow (depth)
                                                        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 2, y: 2)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            } else {
                                                Spacer()
                                                    .frame(maxWidth: .infinity, minHeight: 44)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, StyleGuide.spacing.lg)
                                }
                            }
                            .padding(.bottom, StyleGuide.spacing.md)
                        }
                    }
                    
                    // Divider between books
                    if book.id != bibleManager.getAvailableBooks().last?.id {
                        Rectangle()
                            .fill(StyleGuide.mainBrown.opacity(0.1))
                            .frame(height: 1)
                            .padding(.horizontal, StyleGuide.spacing.lg)
                    }
                }
                }
            }
            .navigationTitle("")
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

// MARK: - Verse Action Menu
private struct VerseActionMenu: View {
    let currentHighlightColor: Color?
    let copyAction: () -> Void
    let interpretAction: () -> Void
    let shareAction: () -> Void
    let saveAction: () -> Void
    let noteAction: () -> Void
    let colorAction: (Color) -> Void
    @State private var buttonsVisible = false
    @State private var colorsVisible = false
    
    private let colors: [Color] = [
        Color.white,
        Color(red: 1, green: 0.96, blue: 0.71), // Light yellow
        Color(red: 0.85, green: 1, blue: 0.85), // Light green
        Color(red: 1, green: 0.85, blue: 0.9), // Light pink
        Color(red: 0.85, green: 0.93, blue: 1), // Light blue
        Color(red: 0.93, green: 0.85, blue: 1)  // Light purple
    ]
    
    // Helper function to check if a color matches the current highlight
    private func isColorSelected(_ color: Color) -> Bool {
        guard let currentColor = currentHighlightColor else {
            return color == .white // If no highlight, white is "selected"
        }
        // Compare colors by converting to UIColor components
        return colorsAreEqual(color, currentColor)
    }
    
    // Helper to compare colors
    private func colorsAreEqual(_ color1: Color, _ color2: Color) -> Bool {
        let uiColor1 = UIColor(color1)
        let uiColor2 = UIColor(color2)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        uiColor1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiColor2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return abs(r1 - r2) < 0.01 && abs(g1 - g2) < 0.01 && abs(b1 - b2) < 0.01
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Copy verse button
            NeuromorphicMenuButton(
                icon: "doc.on.doc",
                title: "Copy verse",
                action: copyAction
            )
            .opacity(buttonsVisible ? 1 : 0)
            .offset(x: buttonsVisible ? 0 : -10)
            
            // Interpret verse button
            NeuromorphicMenuButton(
                icon: "sparkles",
                title: "Interpret verse",
                action: interpretAction
            )
            .opacity(buttonsVisible ? 1 : 0)
            .offset(x: buttonsVisible ? 0 : -10)
            
            // Share verse button
            NeuromorphicMenuButton(
                icon: "square.and.arrow.up",
                title: "Share verse",
                action: shareAction
            )
            .opacity(buttonsVisible ? 1 : 0)
            .offset(x: buttonsVisible ? 0 : -10)
            
            // Save verse button
            NeuromorphicMenuButton(
                icon: "heart",
                title: "Save verse",
                action: saveAction
            )
            .opacity(buttonsVisible ? 1 : 0)
            .offset(x: buttonsVisible ? 0 : -10)
            
            // Add note button
            NeuromorphicMenuButton(
                icon: "note.text",
                title: "Add note",
                action: noteAction
            )
            .opacity(buttonsVisible ? 1 : 0)
            .offset(x: buttonsVisible ? 0 : -10)
            
            // Glassmorphic divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            StyleGuide.mainBrown.opacity(0.08),
                            Color.white.opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
                .padding(.vertical, 4)
                .opacity(buttonsVisible ? 1 : 0)
            
            // Color selection row with staggered animation
            HStack(spacing: 10) {
                ForEach(colors.indices, id: \.self) { idx in
                    let isSelected = isColorSelected(colors[idx])
                    Button(action: {
                        colorAction(colors[idx])
                    }) {
                        Circle()
                            .fill(colors[idx])
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(idx == 0 ? StyleGuide.mainBrown.opacity(0.15) : Color.clear, lineWidth: 0.5)
                            )
                            .overlay(
                                Circle()
                                    .stroke(StyleGuide.mainBrown.opacity(0.8), lineWidth: 2.5)
                                    .scaleEffect(0.75)
                                    .opacity(isSelected ? 1 : 0)
                            )
                    }
                    .buttonStyle(ColorCircleButtonStyle())
                    .scaleEffect(colorsVisible ? 1 : 0.3)
                    .opacity(colorsVisible ? 1 : 0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.6)
                            .delay(Double(idx) * 0.03),
                        value: colorsVisible
                    )
                }
            }
            .padding(.top, 4)
        }
        .onAppear {
            // Stagger the button animations
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75).delay(0.05)) {
                buttonsVisible = true
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75).delay(0.15)) {
                colorsVisible = true
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(
            ZStack {
                // Glassmorphic background with blur
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Subtle gradient overlay for depth (more transparent)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Light refraction effect at the top
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        )
        .overlay(
            // Glass border with subtle shimmer
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.3),
                            StyleGuide.mainBrown.opacity(0.1),
                            Color.white.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        // Soft outer glow for floating glass effect
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        // Subtle highlight on top edge
        .shadow(color: Color.white.opacity(0.6), radius: 1, x: 0, y: -1)
        .frame(width: 230)
    }
}

// MARK: - Neuromorphic Menu Button
private struct NeuromorphicMenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                Text(title)
                    .font(StyleGuide.merriweather(size: 15))
            }
            .foregroundColor(StyleGuide.mainBrown)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(isPressed ? 1 : 0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    .opacity(isPressed ? 1 : 0)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(NeuromorphicButtonStyle(isPressed: $isPressed))
    }
}

// MARK: - Button Styles
private struct NeuromorphicButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { pressed in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isPressed = pressed
                }
            }
    }
}

private struct ColorCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Anchor Preference for Verse Bounds
private struct VerseBoundsPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: Anchor<CGRect>] = [:]
    static func reduce(value: inout [Int: Anchor<CGRect>], nextValue: () -> [Int: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// PreferenceKey to measure the size of the action menu
private struct ActionMenuSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// PreferenceKey to track scroll offset
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// PreferenceKey to detect bottom of scroll
private struct BottomDetectionPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Reading Settings Menu
private struct ReadingSettingsMenu: View {
    @Binding var fontSize: CGFloat
    @Binding var readingMode: ReadingMode
    let minFontSize: CGFloat
    let maxFontSize: CGFloat
    let fontSizeStep: CGFloat
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Reading Mode Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Reading Mode")
                    .font(StyleGuide.merriweather(size: 13, weight: .semibold))
                    .foregroundColor(readingMode.textColor.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                HStack(spacing: 8) {
                    ForEach(ReadingMode.allCases, id: \.self) { mode in
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            withAnimation(.easeInOut(duration: 0.4)) {
                                readingMode = mode
                            }
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(readingMode == mode ? mode.textColor : readingMode.textColor.opacity(0.5))
                                
                                Text(mode.rawValue)
                                    .font(StyleGuide.merriweather(size: 12, weight: readingMode == mode ? .semibold : .regular))
                                    .foregroundColor(readingMode == mode ? mode.textColor : readingMode.textColor.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(readingMode == mode ? mode.backgroundColor : readingMode.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        readingMode == mode ? mode.textColor.opacity(0.3) : readingMode.textColor.opacity(0.1),
                                        lineWidth: readingMode == mode ? 1.5 : 0.8
                                    )
                            )
                            .shadow(color: readingMode == mode ? mode.shadowDark.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            readingMode.shadowLight.opacity(0.3),
                            readingMode.textColor.opacity(0.08),
                            readingMode.shadowLight.opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
            
            // Font Size Section
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Text Size")
                        .font(StyleGuide.merriweather(size: 13, weight: .semibold))
                        .foregroundColor(readingMode.textColor.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Spacer()
                    
                    Text("\(Int(fontSize))pt")
                        .font(StyleGuide.merriweather(size: 13, weight: .medium))
                        .foregroundColor(readingMode.textColor.opacity(0.6))
                }
                
                HStack(spacing: 12) {
                    // Decrease button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if fontSize > minFontSize {
                                fontSize -= fontSizeStep
                                UserDefaults.standard.set(fontSize, forKey: "bibleTextSize")
                            }
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(fontSize <= minFontSize ? readingMode.textColor.opacity(0.3) : readingMode.textColor)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(readingMode.cardBackground)
                            )
                            .overlay(
                                Circle()
                                    .stroke(readingMode.textColor.opacity(0.1), lineWidth: 0.8)
                            )
                            .shadow(color: readingMode.shadowLight, radius: 2, x: -2, y: -2)
                            .shadow(color: readingMode.shadowDark, radius: 2, x: 2, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(fontSize <= minFontSize)
                    
                    // Slider
                    Slider(value: $fontSize, in: minFontSize...maxFontSize, step: fontSizeStep)
                        .accentColor(readingMode.textColor.opacity(0.6))
                        .onChange(of: fontSize) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "bibleTextSize")
                        }
                    
                    // Increase button
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if fontSize < maxFontSize {
                                fontSize += fontSizeStep
                                UserDefaults.standard.set(fontSize, forKey: "bibleTextSize")
                            }
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(fontSize >= maxFontSize ? readingMode.textColor.opacity(0.3) : readingMode.textColor)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(readingMode.cardBackground)
                            )
                            .overlay(
                                Circle()
                                    .stroke(readingMode.textColor.opacity(0.1), lineWidth: 0.8)
                            )
                            .shadow(color: readingMode.shadowLight, radius: 2, x: -2, y: -2)
                            .shadow(color: readingMode.shadowDark, radius: 2, x: 2, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(fontSize >= maxFontSize)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(
            ZStack {
                // Glassmorphic background with blur
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Subtle gradient overlay for depth (more transparent)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Light refraction effect at the top
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        )
        .overlay(
            // Glass border with subtle shimmer
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0.3),
                            readingMode.textColor.opacity(0.1),
                            Color.white.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        // Soft outer glow for floating glass effect
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        // Subtle highlight on top edge
        .shadow(color: Color.white.opacity(0.6), radius: 1, x: 0, y: -1)
    }
}

// MARK: - Chapter Navigation Bar
private struct ChapterNavigationBar: View {
    @ObservedObject var bibleManager: BibleManager
    let readingMode: ReadingMode
    
    // Helper to check if we can navigate to previous chapter
    private var canGoPrevious: Bool {
        if bibleManager.currentChapter > 1 {
            return true
        }
        // Check if there's a previous book
        return bibleManager.currentBook > 1
    }
    
    // Helper to check if we can navigate to next chapter
    private var canGoNext: Bool {
        let maxChapter = bibleManager.getAvailableChapters(for: bibleManager.currentBook).last ?? 0
        if bibleManager.currentChapter < maxChapter {
            return true
        }
        // Check if there's a next book
        let maxBook = bibleManager.getAvailableBooks().last?.id ?? 0
        return bibleManager.currentBook < maxBook
    }
    
    private func goToPreviousChapter() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        if bibleManager.currentChapter > 1 {
            // Go to previous chapter in same book
            bibleManager.loadVerses(book: bibleManager.currentBook, chapter: bibleManager.currentChapter - 1)
        } else if bibleManager.currentBook > 1 {
            // Go to last chapter of previous book
            let previousBook = bibleManager.currentBook - 1
            let lastChapter = bibleManager.getAvailableChapters(for: previousBook).last ?? 1
            bibleManager.loadVerses(book: previousBook, chapter: lastChapter)
        }
    }
    
    private func goToNextChapter() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        let maxChapter = bibleManager.getAvailableChapters(for: bibleManager.currentBook).last ?? 0
        if bibleManager.currentChapter < maxChapter {
            // Go to next chapter in same book
            bibleManager.loadVerses(book: bibleManager.currentBook, chapter: bibleManager.currentChapter + 1)
        } else {
            // Go to first chapter of next book
            let maxBook = bibleManager.getAvailableBooks().last?.id ?? 0
            if bibleManager.currentBook < maxBook {
                bibleManager.loadVerses(book: bibleManager.currentBook + 1, chapter: 1)
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Previous Chapter Button
            Button(action: goToPreviousChapter) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canGoPrevious ? readingMode.textColor : readingMode.textColor.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .background(
                        ZStack {
                            // Glassmorphic background with blur
                            Circle()
                                .fill(.ultraThinMaterial)
                            
                            // Subtle gradient overlay for depth
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.1),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            // Light refraction effect at the top
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                        }
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.3),
                                        readingMode.textColor.opacity(0.1),
                                        Color.white.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                    .shadow(color: Color.white.opacity(0.6), radius: 1, x: 0, y: -1)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canGoPrevious)
            
            Spacer()
            
            // Next Chapter Button
            Button(action: goToNextChapter) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canGoNext ? readingMode.textColor : readingMode.textColor.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .background(
                        ZStack {
                            // Glassmorphic background with blur
                            Circle()
                                .fill(.ultraThinMaterial)
                            
                            // Subtle gradient overlay for depth
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.1),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            // Light refraction effect at the top
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                        }
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.8),
                                        Color.white.opacity(0.3),
                                        readingMode.textColor.opacity(0.1),
                                        Color.white.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                    .shadow(color: Color.white.opacity(0.6), radius: 1, x: 0, y: -1)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!canGoNext)
        }
    }
}

