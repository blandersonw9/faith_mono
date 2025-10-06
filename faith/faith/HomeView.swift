import SwiftUI
import Supabase


// MARK: - Tab Content Views
struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userDataManager: UserDataManager
    @StateObject private var dailyLessonManager: DailyLessonManager
    @State private var showingProfile = false
    
    init() {
        let auth = AuthManager()
        _dailyLessonManager = StateObject(wrappedValue: DailyLessonManager(supabase: auth.supabase))
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let horizontalPadding = geometry.size.width * 0.025
                
                ScrollView {
                VStack(spacing: StyleGuide.spacing.xl) {
                    // Top spacing to prevent cross cutoff
                    Spacer()
                        .frame(height: 40)
                    
                    // Header with cross background
                    ZStack(alignment: .top) {
                        // Cross - 220px height with proper spacing
                        Image("crossFill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 220)
                            .foregroundColor(StyleGuide.gold)
                    }
                    .padding(.bottom, -80) // Negative padding to pull content up without offset
                    
                    // Weekly Streak Section
                    WeeklyStreakView(userDataManager: userDataManager, showingProfile: $showingProfile)
                        .padding(.horizontal, horizontalPadding)
                        .zIndex(1) // Ensure it's above other content
                    
                    // Today Content Section
                    TodayContent(dailyLessonManager: dailyLessonManager, userDataManager: userDataManager)
                        .padding(.horizontal, horizontalPadding)
                    
                    // Bottom spacing for better scrolling
                    Spacer()
                        .frame(height: 40)
                }
                }
                .onAppear {
                    Task {
                        await userDataManager.fetchUserData()
                        await dailyLessonManager.fetchTodaysLesson()
                    }
                }
                .refreshable {
                    await userDataManager.fetchUserData()
                    await dailyLessonManager.fetchTodaysLesson()
                }
            }
            .navigationDestination(isPresented: $showingProfile) {
                ProfileView(userDataManager: userDataManager)
                    .environmentObject(authManager)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}


// MARK: - Today Content
struct TodayContent: View {
    @ObservedObject var dailyLessonManager: DailyLessonManager
    @ObservedObject var userDataManager: UserDataManager
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
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .background(
            ZStack {
                // Background image
                Group {
                    if let cachedImage = dailyLessonManager.preloadedFirstImage {
                        // Use preloaded image for instant display
                        Image(uiImage: cachedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        // Fallback to hardcoded image while loading
                        Image("backgroundCard")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
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
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 20, x: 0, y: 8)
        .fullScreenCover(isPresented: $showLesson) {
            DailyLessonSlideView(dailyLessonManager: dailyLessonManager, userDataManager: userDataManager)
                .ignoresSafeArea()
        }
        .onChange(of: showLesson) { isShowing in
            // Refresh data when returning from lesson
            if !isShowing {
                Task {
                    await userDataManager.fetchUserData()
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
                        Text(userDataManager.getDisplayName())
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
