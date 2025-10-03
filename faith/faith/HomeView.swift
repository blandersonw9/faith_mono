import SwiftUI
import Supabase


// MARK: - Tab Content Views
struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var userDataManager: UserDataManager
    @StateObject private var dailyLessonManager: DailyLessonManager
    @State private var showingProfile = false
    
    init(authManager: AuthManager) {
        _userDataManager = StateObject(wrappedValue: UserDataManager(supabase: authManager.supabase, authManager: authManager))
        _dailyLessonManager = StateObject(wrappedValue: DailyLessonManager(supabase: authManager.supabase))
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
                    
                    // Weekly Streak Section
                    WeeklyStreakView(userDataManager: userDataManager, showingProfile: $showingProfile)
                        .padding(.horizontal, horizontalPadding)
                        .offset(y: -80)
                    
                    // Today Content Section
                    TodayContent(dailyLessonManager: dailyLessonManager)
                        .padding(.horizontal, horizontalPadding)
                        .offset(y: -80)
                    
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
    
    var body: some View {
        VStack(spacing: 28) {
            // TOP: Daily practice date
            Text("Daily practice | September 24th")
                .font(StyleGuide.merriweather(size: 12, weight: .regular))
                .foregroundColor(StyleGuide.backgroundBeige.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .center)
            
            // CENTER: Bible verse
            Text("Father forgive them, for they do not\nknow what they are doing")
                .font(StyleGuide.merriweather(size: 16, weight: .regular))
                .foregroundColor(StyleGuide.backgroundBeige)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .lineSpacing(12)
            
            // BOTTOM: Continue button
            NavigationLink(destination: DailyLessonSlideView(dailyLessonManager: dailyLessonManager)) {
                Text("Continue")
                    .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                    .foregroundColor(StyleGuide.mainBrown)
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
                    .background(StyleGuide.backgroundBeige)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .background(
            Image("backgroundCard")
                .resizable()
                .aspectRatio(contentMode: .fill)
        )
        .cornerRadius(12)
    }
}

// MARK: - Weekly Streak View
struct WeeklyStreakView: View {
    @ObservedObject var userDataManager: UserDataManager
    @Binding var showingProfile: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let streakWidth = screenWidth * 0.90
            let dayStates = userDataManager.getWeekDayStates()
            
            HStack {
                Spacer()
                
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
                        }
                        .buttonStyle(PlainButtonStyle())
                        
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
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(width: streakWidth)
                .background(StyleGuide.backgroundBeige)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(StyleGuide.mainBrown.opacity(0.25), lineWidth: 1)
                )
                .cornerRadius(12)
                
                Spacer()
            }
        }
        .frame(height: 80)
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
            return Color(hex: "D4AF37") // Gold text for completed
        case .current:
            return .white // White text on gold background
        case .incomplete:
            return Color(hex: "D4AF37").opacity(0.5) // Light blue-gray for incomplete
        }
    }
    
    var body: some View {
        ZStack {
            // Streak image based on state
            Group {
                switch dayState {
                case .complete:
                    Image("streakFill")
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
                    Image("streakActive")
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

enum DayState {
    case complete     // Day completed successfully
    case incomplete   // Day not completed (includes past and future)
    case current      // Current day
}
