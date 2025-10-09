//
//  SessionStoriesView.swift
//  faith
//
//  Stories-style walkthrough for Bible study sessions
//

import SwiftUI

struct SessionStoriesView: View {
    @Environment(\.dismiss) private var dismiss
    let session: StudySession
    let unitTitle: String
    @State private var currentStoryIndex = 0
    @State private var progress: [Double]
    @GestureState private var dragOffset: CGFloat = 0
    
    // Define story sections
    private var stories: [StorySection] {
        var sections: [StorySection] = []
        
        // 1. Passages
        sections.append(.passages(session.passages))
        
        // 2. Context
        if let context = session.context, !context.isEmpty {
            sections.append(.context(context))
        }
        
        // 3. Key Insights
        if !session.keyInsights.isEmpty {
            sections.append(.insights(session.keyInsights))
        }
        
        // 4. Reflection Questions
        if !session.reflectionQuestions.isEmpty {
            sections.append(.questions(session.reflectionQuestions))
        }
        
        // 5. Prayer
        if let prayer = session.prayerPrompt, !prayer.isEmpty {
            sections.append(.prayer(prayer))
        }
        
        // 6. Action Step
        if let action = session.actionStep, !action.isEmpty {
            sections.append(.action(action))
        }
        
        // 7. Memory Verse
        if let verse = session.memoryVerse, !verse.isEmpty {
            sections.append(.memoryVerse(verse))
        }
        
        return sections
    }
    
    init(session: StudySession, unitTitle: String) {
        self.session = session
        self.unitTitle = unitTitle
        let storyCount = SessionStoriesView.calculateStoryCount(session: session)
        _progress = State(initialValue: Array(repeating: 0.0, count: storyCount))
    }
    
    private static func calculateStoryCount(session: StudySession) -> Int {
        var count = 1 // Passages always exists
        if session.context != nil && !(session.context?.isEmpty ?? true) { count += 1 }
        if !session.keyInsights.isEmpty { count += 1 }
        if !session.reflectionQuestions.isEmpty { count += 1 }
        if session.prayerPrompt != nil && !(session.prayerPrompt?.isEmpty ?? true) { count += 1 }
        if session.actionStep != nil && !(session.actionStep?.isEmpty ?? true) { count += 1 }
        if session.memoryVerse != nil && !(session.memoryVerse?.isEmpty ?? true) { count += 1 }
        return count
    }
    
    var body: some View {
        ZStack {
            // Background
            StyleGuide.backgroundBeige
                .ignoresSafeArea()
            
            // Current story content
            if currentStoryIndex < stories.count {
                StoryContentView(
                    section: stories[currentStoryIndex],
                    sessionTitle: session.title,
                    unitTitle: unitTitle
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            }
            
            // Tap zones for navigation
            HStack(spacing: 0) {
                // Left tap zone - previous
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        goToPrevious()
                    }
                
                // Right tap zone - next
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        goToNext()
                    }
            }
            
            // Progress bars at top
            VStack {
                HStack(spacing: 4) {
                    ForEach(0..<stories.count, id: \.self) { index in
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 3)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: geo.size.width * CGFloat(progressForBar(index)), height: 3)
                            }
                        }
                        .frame(height: 3)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                
                // Close button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
        .onAppear {
            startProgressAnimation()
        }
    }
    
    private func progressForBar(_ index: Int) -> Double {
        if index < currentStoryIndex {
            return 1.0
        } else if index == currentStoryIndex {
            return progress[index]
        } else {
            return 0.0
        }
    }
    
    private func startProgressAnimation() {
        guard currentStoryIndex < stories.count else { return }
        
        withAnimation(.linear(duration: 5.0)) {
            progress[currentStoryIndex] = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if currentStoryIndex < stories.count - 1 {
                goToNext()
            }
        }
    }
    
    private func goToNext() {
        guard currentStoryIndex < stories.count - 1 else {
            dismiss()
            return
        }
        
        withAnimation {
            progress[currentStoryIndex] = 1.0
            currentStoryIndex += 1
        }
        
        startProgressAnimation()
    }
    
    private func goToPrevious() {
        guard currentStoryIndex > 0 else { return }
        
        withAnimation {
            progress[currentStoryIndex] = 0.0
            currentStoryIndex -= 1
            progress[currentStoryIndex] = 0.0
        }
        
        startProgressAnimation()
    }
}

// MARK: - Story Section Enum

enum StorySection {
    case passages([String])
    case context(String)
    case insights([String])
    case questions([String])
    case prayer(String)
    case action(String)
    case memoryVerse(String)
}

// MARK: - Story Content View

struct StoryContentView: View {
    let section: StorySection
    let sessionTitle: String
    let unitTitle: String
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 80)
            
            ScrollView {
                VStack(alignment: .leading, spacing: StyleGuide.spacing.xl) {
                    // Session context
                    VStack(alignment: .leading, spacing: 4) {
                        Text(unitTitle)
                            .font(StyleGuide.merriweather(size: 12, weight: .medium))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                        
                        Text(sessionTitle)
                            .font(StyleGuide.merriweather(size: 16, weight: .bold))
                            .foregroundColor(StyleGuide.mainBrown)
                    }
                    
                    // Section-specific content
                    switch section {
                    case .passages(let passages):
                        StoryPassagesContent(passages: passages)
                        
                    case .context(let text):
                        StoryContextContent(text: text)
                        
                    case .insights(let insights):
                        StoryInsightsContent(insights: insights)
                        
                    case .questions(let questions):
                        StoryQuestionsContent(questions: questions)
                        
                    case .prayer(let text):
                        StoryPrayerContent(text: text)
                        
                    case .action(let text):
                        StoryActionContent(text: text)
                        
                    case .memoryVerse(let verse):
                        StoryMemoryVerseContent(verse: verse)
                    }
                }
                .padding(.horizontal, StyleGuide.spacing.xl)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Story Content Components

struct StoryPassagesContent: View {
    let passages: [String]
    @State private var loadedVerses: [String: [BibleVerse]] = [:]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 8) {
                Image(systemName: "book.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                
                Text("Passages")
                    .font(StyleGuide.merriweather(size: 32, weight: .bold))
                    .foregroundColor(StyleGuide.mainBrown)
            }
            
            ForEach(passages, id: \.self) { passage in
                VStack(alignment: .leading, spacing: 12) {
                    // Reference
                    Text(passage)
                        .font(StyleGuide.merriweather(size: 18, weight: .bold))
                        .foregroundColor(StyleGuide.gold)
                    
                    // Verse text
                    if let verses = loadedVerses[passage], !verses.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(verses, id: \.id) { verse in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(verse.verse)")
                                        .font(StyleGuide.merriweather(size: 13, weight: .bold))
                                        .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                                        .frame(width: 24, alignment: .trailing)
                                    
                                    Text(verse.text)
                                        .font(StyleGuide.merriweather(size: 17, weight: .medium))
                                        .foregroundColor(StyleGuide.mainBrown.opacity(0.9))
                                        .lineSpacing(4)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(12)
                    } else {
                        ProgressView()
                            .padding()
                    }
                }
            }
        }
        .onAppear {
            loadAllVerses()
        }
    }
    
    private func loadAllVerses() {
        for passage in passages {
            let verses = VerseRetriever.fetchVerses(reference: passage)
            loadedVerses[passage] = verses
        }
    }
}

struct StoryContextContent: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                
                Text("Context")
                    .font(StyleGuide.merriweather(size: 32, weight: .bold))
                    .foregroundColor(StyleGuide.mainBrown)
            }
            
            Text(text)
                .font(StyleGuide.merriweather(size: 18, weight: .medium))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
                .lineSpacing(6)
        }
    }
}

struct StoryInsightsContent: View {
    let insights: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 32))
                    .foregroundColor(StyleGuide.gold)
                
                Text("Key Insights")
                    .font(StyleGuide.merriweather(size: 32, weight: .bold))
                    .foregroundColor(StyleGuide.mainBrown)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(insights.enumerated()), id: \.offset) { index, insight in
                    HStack(alignment: .top, spacing: 12) {
                        Text("•")
                            .font(StyleGuide.merriweather(size: 24, weight: .bold))
                            .foregroundColor(StyleGuide.gold)
                        
                        Text(insight)
                            .font(StyleGuide.merriweather(size: 18, weight: .medium))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

struct StoryQuestionsContent: View {
    let questions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.purple)
                
                Text("Reflect")
                    .font(StyleGuide.merriweather(size: 32, weight: .bold))
                    .foregroundColor(StyleGuide.mainBrown)
            }
            
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question \(index + 1)")
                            .font(StyleGuide.merriweather(size: 12, weight: .semibold))
                            .foregroundColor(.purple.opacity(0.7))
                        
                        Text(question)
                            .font(StyleGuide.merriweather(size: 18, weight: .medium))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

struct StoryPrayerContent: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "hands.clap.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
                
                Text("Prayer")
                    .font(StyleGuide.merriweather(size: 32, weight: .bold))
                    .foregroundColor(StyleGuide.mainBrown)
            }
            
            Text(text)
                .font(StyleGuide.merriweatherItalic(size: 18))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
                .lineSpacing(6)
        }
    }
}

struct StoryActionContent: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 32))
                    .foregroundColor(.red)
                
                Text("Action Step")
                    .font(StyleGuide.merriweather(size: 32, weight: .bold))
                    .foregroundColor(StyleGuide.mainBrown)
            }
            
            Text(text)
                .font(StyleGuide.merriweather(size: 20, weight: .semibold))
                .foregroundColor(StyleGuide.mainBrown)
                .lineSpacing(6)
        }
    }
}

struct StoryMemoryVerseContent: View {
    let verse: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32))
                    .foregroundColor(.indigo)
                
                Text("Memory Verse")
                    .font(StyleGuide.merriweather(size: 32, weight: .bold))
                    .foregroundColor(StyleGuide.mainBrown)
            }
            
            VStack(spacing: 12) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 24))
                    .foregroundColor(StyleGuide.gold.opacity(0.3))
                
                Text(verse)
                    .font(StyleGuide.merriweather(size: 22, weight: .bold))
                    .foregroundColor(StyleGuide.gold)
                    .multilineTextAlignment(.center)
                
                Image(systemName: "quote.closing")
                    .font(.system(size: 24))
                    .foregroundColor(StyleGuide.gold.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

