import SwiftUI
import Supabase

// MARK: - Progress Cross View
struct ProgressCrossView: View {
    @ObservedObject var userDataManager: UserDataManager
    
    private var currentStreak: Int {
        userDataManager.getCurrentStreak()
    }
    
    private func nextBadge(for streak: Int) -> StreakBadge? {
        StreakBadge.allBadges.first(where: { $0.daysRequired > streak })
    }
    
    private func progressToNext(for streak: Int) -> Double {
        guard let next = nextBadge(for: streak) else {
            return 1.0 // All badges earned
        }
        
        let previousMilestone = StreakBadge.allBadges
            .filter { $0.daysRequired <= streak }
            .last?.daysRequired ?? 0
        
        let range = Double(next.daysRequired - previousMilestone)
        let progress = Double(streak - previousMilestone)
        
        return min(progress / range, 1.0)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background cross (outline)
                Image("faithCrossOutline")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Filled cross (progress) - masked from bottom up with wavy top
                Image("faithCrossFilled")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .mask(
                        GeometryReader { geo in
                            VStack(spacing: 0) {
                                Spacer()
                                ZStack(alignment: .bottom) {
                                    // Main fill rectangle
                                    Rectangle()
                                        .frame(height: geo.size.height * progressToNext(for: currentStreak))
                                    
                                    // Wavy top edge (only show if not at 0% or 100%)
                                    if progressToNext(for: currentStreak) > 0.01 && progressToNext(for: currentStreak) < 0.99 {
                                        WavyEdge()
                                            .fill(Color.white)
                                            .frame(height: 40)
                                            .offset(y: -geo.size.height * progressToNext(for: currentStreak) + 20)
                                    }
                                }
                            }
                        }
                    )
                    .animation(.easeInOut(duration: 0.5), value: progressToNext(for: currentStreak))
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

// MARK: - Badge Progress Sheet
struct BadgeProgressSheet: View {
    let currentStreak: Int
    let nextBadge: StreakBadge?
    let progress: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                StyleGuide.backgroundBeige
                    .ignoresSafeArea()
                
                VStack(spacing: StyleGuide.spacing.xl) {
                    Spacer()
                        .frame(height: 20)
                    
                    if let next = nextBadge {
                        // Next badge preview
                        Image("\(next.assetName)Unfilled")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                            .opacity(0.8)
                        
                        // Badge name
                        Text(next.name)
                            .font(StyleGuide.merriweather(size: 28, weight: .bold))
                            .foregroundColor(StyleGuide.mainBrown)
                        
                        // Days remaining
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(StyleGuide.gold)
                                
                                Text("\(next.daysRequired - currentStreak)")
                                    .font(StyleGuide.merriweather(size: 48, weight: .bold))
                                    .foregroundColor(StyleGuide.gold)
                            }
                            
                            Text(next.daysRequired - currentStreak == 1 ? "day to go" : "days to go")
                                .font(StyleGuide.merriweather(size: 16, weight: .medium))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                        }
                        .padding(.vertical, StyleGuide.spacing.lg)
                        .padding(.horizontal, StyleGuide.spacing.xl)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(StyleGuide.gold.opacity(0.1))
                        )
                        
                        // Progress percentage
                        VStack(spacing: 8) {
                            HStack {
                                Text("Progress")
                                    .font(StyleGuide.merriweather(size: 14, weight: .medium))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                                
                                Spacer()
                                
                                Text("\(Int(progress * 100))%")
                                    .font(StyleGuide.merriweather(size: 14, weight: .bold))
                                    .foregroundColor(StyleGuide.gold)
                            }
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(StyleGuide.mainBrown.opacity(0.1))
                                        .frame(height: 12)
                                    
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(
                                            LinearGradient(
                                                colors: [StyleGuide.gold, StyleGuide.gold.opacity(0.7)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * progress, height: 12)
                                }
                            }
                            .frame(height: 12)
                        }
                        .padding(.horizontal, StyleGuide.spacing.xl)
                        
                        // Description
                        Text(next.description)
                            .font(StyleGuide.merriweather(size: 15, weight: .medium))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, StyleGuide.spacing.xl)
                        
                    } else {
                        // All badges earned
                        Image("badgeYear")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                        
                        Text("All Badges Earned! 🎉")
                            .font(StyleGuide.merriweather(size: 28, weight: .bold))
                            .foregroundColor(StyleGuide.gold)
                        
                        Text("You've completed all streak milestones!")
                            .font(StyleGuide.merriweather(size: 15, weight: .medium))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, StyleGuide.spacing.xl)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Badge Progress")
                        .font(StyleGuide.merriweather(size: 18, weight: .semibold))
                        .foregroundColor(StyleGuide.mainBrown)
                }
                
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

// MARK: - Wavy Edge Shape
struct WavyEdge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Start from bottom left
        path.move(to: CGPoint(x: 0, y: height))
        
        // Draw wavy top edge - more pronounced waves
        let waveCount = 4.0
        let waveWidth = width / waveCount
        let waveAmplitude = height // Full height for more pronounced waves
        
        for i in 0..<Int(waveCount) {
            let startX = CGFloat(i) * waveWidth
            let endX = startX + waveWidth
            
            // Create pronounced wave with control points
            path.addCurve(
                to: CGPoint(x: endX, y: height),
                control1: CGPoint(x: startX + waveWidth * 0.25, y: 0),
                control2: CGPoint(x: startX + waveWidth * 0.75, y: 0)
            )
        }
        
        // Complete the shape
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Tab Content Views
struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userDataManager: UserDataManager
    @EnvironmentObject var bibleNavigator: BibleNavigator
    @EnvironmentObject var dailyLessonManager: DailyLessonManager
    @State private var showingProfile = false
    @State private var showBadgeProgress = false
    
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
        GeometryReader { geometry in
                let horizontalPadding = max(geometry.size.width * 0.025, 16)
                let maxContentWidth: CGFloat = isIPad ? 600 : .infinity
                let contentWidth = min(geometry.size.width, maxContentWidth)
                
                ScrollView {
                HStack {
                    Spacer(minLength: 0)
                    VStack(spacing: StyleGuide.spacing.xl) {
                        // Top spacing to prevent cross cutoff
                        Spacer()
                            .frame(height: isIPad ? 320 : 40)
                        
                        // Header with progress-filled cross
                        ProgressCrossView(userDataManager: userDataManager)
                            .frame(height: isIPad ? 240 : 220)
                            .padding(.bottom, isIPad ? -80 : -80)
                            .onTapGesture {
                                print("🎯 Cross tapped!")
                                showBadgeProgress = true
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                            .zIndex(-1) // Behind the weekly view
                        
                        // Weekly Streak Section
                        WeeklyStreakView(userDataManager: userDataManager, showingProfile: $showingProfile)
                            .padding(.horizontal, horizontalPadding + 16)
                            .zIndex(1) // Above the cross
                        
                        // Today Content Section
                        TodayContent()
                            .padding(.horizontal, 16)
                        
                        // Bottom spacing for better scrolling
                        Spacer()
                            .frame(height: isIPad ? 100 : 120)
                    }
                    .frame(width: contentWidth)
                    Spacer(minLength: 0)
                }
                .frame(width: geometry.size.width)
                }
                .scrollIndicators(.hidden)
                .onAppear {
                    // Only fetch lesson - user data is already loaded by faithApp
                    Task {
                        await dailyLessonManager.fetchTodaysLesson()
                    }
                }
                .refreshable {
                    // Allow manual refresh of both
                    await userDataManager.fetchUserData()
                    await dailyLessonManager.fetchTodaysLesson()
                }
                .sheet(isPresented: $showBadgeProgress) {
                    BadgeProgressSheet(
                        currentStreak: userDataManager.getCurrentStreak(),
                        nextBadge: StreakBadge.allBadges.first(where: { $0.daysRequired > userDataManager.getCurrentStreak() }),
                        progress: {
                            let streak = userDataManager.getCurrentStreak()
                            guard let next = StreakBadge.allBadges.first(where: { $0.daysRequired > streak }) else {
                                return 1.0
                            }
                            let previousMilestone = StreakBadge.allBadges.filter { $0.daysRequired <= streak }.last?.daysRequired ?? 0
                            let range = Double(next.daysRequired - previousMilestone)
                            let progress = Double(streak - previousMilestone)
                            return min(progress / range, 1.0)
                        }()
                    )
                }
            }
            .navigationDestination(isPresented: $showingProfile) {
                ProfileView(userDataManager: userDataManager)
                    .environmentObject(authManager)
                    .environmentObject(bibleNavigator)
            }
    }
}


// MARK: - Today Content
struct TodayContent: View {
    @EnvironmentObject var dailyLessonManager: DailyLessonManager
    @EnvironmentObject var userDataManager: UserDataManager
    @State private var showLesson: Bool = false
    
    // Get today's date formatted
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        let dateString = formatter.string(from: Date())
        
        // Add ordinal suffix (st, nd, rd, th)
        let day = Calendar.current.component(.day, from: Date())
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        
        return dateString + suffix
    }
    
    // Get the first scripture slide's verse text
    private var scriptureText: String {
        guard let lesson = dailyLessonManager.currentLesson,
              let scriptureSlide = lesson.slides.first(where: { $0.slideType == .scripture }),
              let verseText = scriptureSlide.verseText else {
            return "Father forgive them, for they do not\nknow what they are doing"
        }
        return verseText
    }
    
    // Determine button state based on progress
    private var buttonText: String {
        // Check if today is completed
        let today = Date()
        if userDataManager.isDateCompleted(today) {
            return "Review"
        }
        
        // Check if lesson is in progress
        if let progress = dailyLessonManager.currentProgress,
           progress.currentSlideIndex > 0,
           !progress.isCompleted {
            return "Continue"
        }
        
        // Not started
        return "Start"
    }
    
    private var buttonBackgroundColor: Color {
        let today = Date()
        if userDataManager.isDateCompleted(today) {
            return StyleGuide.mainBrown.opacity(0.3)
        }
        return StyleGuide.backgroundBeige
    }
    
    private var buttonTextColor: Color {
        let today = Date()
        if userDataManager.isDateCompleted(today) {
            return .white.opacity(0.7)
        }
        return StyleGuide.mainBrown
    }
    
    var body: some View {
        VStack(spacing: 28) {
            // TOP: Daily practice date (dynamic)
            Text("Daily practice | \(formattedDate)")
                .font(StyleGuide.merriweather(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // CENTER: Bible verse (from today's lesson)
            Text(scriptureText)
                .font(StyleGuide.merriweather(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .lineSpacing(6)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
            
            // BOTTOM: Dynamic button (Start / Continue / Review)
            Button(action: { showLesson = true }) {
                Text(buttonText)
                    .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                    .foregroundColor(buttonTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
                    .background(buttonBackgroundColor)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
        .padding(20)
        .background(
            ZStack {
                // Background image - constrained to the card size
                Group {
                    if let cachedImage = dailyLessonManager.preloadedFirstImage {
                        // Use preloaded image for instant display
                        Image(uiImage: cachedImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        // Fallback to hardcoded image while loading
                        Image("backgroundCard")
                            .resizable()
                            .scaledToFill()
                    }
                }
                
                // Dark overlay for text readability
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.35),
                        Color.black.opacity(0.25),
                        Color.black.opacity(0.35)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 8)
        .fullScreenCover(isPresented: $showLesson) {
            DailyLessonSlideView(dailyLessonManager: dailyLessonManager, userDataManager: userDataManager)
                .ignoresSafeArea()
        }
        .onChange(of: showLesson) { isShowing in
            // Refresh only lesson data when returning - user data refresh handled by ContentView scenePhase
            if !isShowing {
                Task {
                    await dailyLessonManager.fetchTodaysLesson()
                }
            }
        }
    }
}

// MARK: - Weekly Streak View
struct WeeklyStreakView: View {
    @ObservedObject var userDataManager: UserDataManager
    @Binding var showingProfile: Bool
    
    var body: some View {
        let dayStates = userDataManager.getWeekDayStates()
        
        VStack(spacing: 16) {
            // First row: NAME -------- Streak
            HStack {
                // Username button - navigates to profile
                Button(action: {
                    showingProfile = true
                }) {
                    HStack(spacing: 4) {
                        Text(userDataManager.getFirstName())
                            .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                            .foregroundColor(StyleGuide.mainBrown)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.4))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                HStack(spacing: StyleGuide.spacing.xs) {
                    Image("streak")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                    
                    Text("\(userDataManager.getCurrentStreak())")
                        .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                        .foregroundColor(StyleGuide.gold)
                }
            }
            
            // Second row: circles with each day of week
            HStack(spacing: 8) {
                ForEach(0..<7) { day in
                    DayCircle(dayIndex: day, dayState: dayStates[day])
                        .id("\(day)-\(dayStates[day].hashValue)")
                }
            }
            .id(dayStates.hashValue)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(StyleGuide.backgroundBeige)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(StyleGuide.mainBrown.opacity(0.25), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .shadow(color: .black.opacity(0.04), radius: 16, x: 0, y: 4)
        .frame(height: 100)
    }
}

// MARK: - Day Circle
struct DayCircle: View {
    let dayIndex: Int
    let dayState: DayState
    
    private var dayAbbreviation: String {
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        return days[dayIndex]
    }
    
    private var fillColor: Color {
        switch dayState {
        case .complete:
            return StyleGuide.mainBrown
        case .current:
            return StyleGuide.gold
        case .incomplete:
            return Color.clear
        }
    }
    
    private var strokeColor: Color {
        switch dayState {
        case .complete:
            return StyleGuide.mainBrown
        case .current:
            return StyleGuide.gold
        case .incomplete:
            return StyleGuide.mainBrown.opacity(0.25)
        }
    }
    
    private var textColor: Color {
        switch dayState {
        case .complete:
            return .white // White text on completed (brown) background
        case .current:
            return Color(hex: "D4AF37") // Gold text on current day
        case .incomplete:
            return Color(hex: "D4AF37").opacity(0.5) // Faded gold for incomplete
        }
    }
    
    var body: some View {
        ZStack {
            // Streak image based on state
            Group {
                switch dayState {
                case .complete:
                    Image("streakActive")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                case .incomplete:
                    Image("streakFill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .opacity(0.5)
                case .current:
                    Image("streakFill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                }
            }
            
            // Day abbreviation text inside
            Text(dayAbbreviation)
                .font(StyleGuide.merriweather(size: 12, weight: .medium))
                .foregroundColor(textColor)
        }
        .frame(width: 36, height: 36)
    }
}

enum DayState: Hashable {
    case complete     // Day completed successfully
    case incomplete   // Day not completed (includes past and future)
    case current      // Current day
}
