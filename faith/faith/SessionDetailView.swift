//
//  SessionDetailView.swift
//  faith
//
//  Detailed view for a single study session
//

import SwiftUI

struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var customStudyManager: CustomStudyManager
    let session: StudySession
    let unitTitle: String
    @State private var isCompleted: Bool = false
    @State private var showStories = false
    @State private var loadedVerses: [String: [BibleVerse]] = [:]
    
    init(session: StudySession, unitTitle: String) {
        self.session = session
        self.unitTitle = unitTitle
        _isCompleted = State(initialValue: session.isCompleted)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                StyleGuide.backgroundBeige
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: StyleGuide.spacing.xl) {
                        // Start Stories Button
                        Button(action: { showStories = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Start Walkthrough")
                                        .font(StyleGuide.merriweather(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("Tap to go through this session step-by-step")
                                        .font(StyleGuide.merriweather(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(
                                LinearGradient(
                                    colors: [StyleGuide.gold, StyleGuide.gold.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: StyleGuide.gold.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, StyleGuide.spacing.lg)
                        
                        // Session Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text(unitTitle)
                                .font(StyleGuide.merriweather(size: 14, weight: .medium))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                            
                            Text(session.title)
                                .font(StyleGuide.merriweather(size: 28, weight: .bold))
                                .foregroundColor(StyleGuide.mainBrown)
                        }
                        .padding(.top, StyleGuide.spacing.lg)
                        
                        // Passages with actual verse text
                        ContentSection(
                            title: "Passages",
                            icon: "book.fill",
                            iconColor: .blue
                        ) {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(session.passages, id: \.self) { passage in
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Reference
                                        Text(passage)
                                            .font(StyleGuide.merriweather(size: 16, weight: .bold))
                                            .foregroundColor(StyleGuide.gold)
                                        
                                        // Verse text
                                        if let verses = loadedVerses[passage], !verses.isEmpty {
                                            VStack(alignment: .leading, spacing: 6) {
                                                ForEach(verses, id: \.id) { verse in
                                                    HStack(alignment: .top, spacing: 6) {
                                                        Text("\(verse.verse)")
                                                            .font(StyleGuide.merriweather(size: 11, weight: .semibold))
                                                            .foregroundColor(StyleGuide.mainBrown.opacity(0.4))
                                                            .frame(width: 20, alignment: .trailing)
                                                        
                                                        Text(verse.text)
                                                            .font(StyleGuide.merriweather(size: 15, weight: .medium))
                                                            .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
                                                            .lineSpacing(3)
                                                    }
                                                }
                                            }
                                            .padding(12)
                                            .background(StyleGuide.backgroundBeige)
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Context
                        if let context = session.context, !context.isEmpty {
                            ContentSection(
                                title: "Context",
                                icon: "map.fill",
                                iconColor: .orange
                            ) {
                                Text(context)
                                    .font(StyleGuide.merriweather(size: 15, weight: .medium))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
                                    .lineSpacing(4)
                            }
                        }
                        
                        // Key Insights
                        if !session.keyInsights.isEmpty {
                            ContentSection(
                                title: "Key Insights",
                                icon: "lightbulb.fill",
                                iconColor: StyleGuide.gold
                            ) {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(session.keyInsights.enumerated()), id: \.offset) { index, insight in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("•")
                                                .font(StyleGuide.merriweather(size: 16, weight: .bold))
                                                .foregroundColor(StyleGuide.gold)
                                            
                                            Text(insight)
                                                .font(StyleGuide.merriweather(size: 15, weight: .medium))
                                                .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Reflection Questions
                        if !session.reflectionQuestions.isEmpty {
                            ContentSection(
                                title: "Reflection Questions",
                                icon: "questionmark.circle.fill",
                                iconColor: .purple
                            ) {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(Array(session.reflectionQuestions.enumerated()), id: \.offset) { index, question in
                                        HStack(alignment: .top, spacing: 8) {
                                            Text("\(index + 1).")
                                                .font(StyleGuide.merriweather(size: 15, weight: .bold))
                                                .foregroundColor(.purple)
                                            
                                            Text(question)
                                                .font(StyleGuide.merriweather(size: 15, weight: .medium))
                                                .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Prayer Prompt
                        if let prayer = session.prayerPrompt, !prayer.isEmpty {
                            ContentSection(
                                title: "Prayer",
                                icon: "hands.clap.fill",
                                iconColor: .green
                            ) {
                                Text(prayer)
                                    .font(StyleGuide.merriweather(size: 15, weight: .medium))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.8))
                                    .lineSpacing(4)
                                    .italic()
                            }
                        }
                        
                        // Action Step
                        if let action = session.actionStep, !action.isEmpty {
                            ContentSection(
                                title: "Action Step",
                                icon: "figure.walk",
                                iconColor: .red
                            ) {
                                Text(action)
                                    .font(StyleGuide.merriweather(size: 15, weight: .semibold))
                                    .foregroundColor(StyleGuide.mainBrown)
                            }
                        }
                        
                        // Memory Verse
                        if let memoryVerse = session.memoryVerse, !memoryVerse.isEmpty {
                            ContentSection(
                                title: "Memory Verse",
                                icon: "brain.head.profile",
                                iconColor: .indigo
                            ) {
                                Text(memoryVerse)
                                    .font(StyleGuide.merriweather(size: 15, weight: .bold))
                                    .foregroundColor(StyleGuide.gold)
                            }
                        }
                        
                        // Cross References
                        if !session.crossReferences.isEmpty {
                            ContentSection(
                                title: "Cross References",
                                icon: "link",
                                iconColor: .cyan
                            ) {
                                FlowLayout(spacing: 8) {
                                    ForEach(session.crossReferences, id: \.self) { reference in
                                        Text(reference)
                                            .font(StyleGuide.merriweather(size: 13, weight: .medium))
                                            .foregroundColor(StyleGuide.mainBrown)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(StyleGuide.gold.opacity(0.15))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, StyleGuide.spacing.xl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Session \(session.sessionIndex + 1)")
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
            .safeAreaInset(edge: .bottom) {
                // Mark Complete Button
                Button(action: { toggleComplete() }) {
                    HStack(spacing: 8) {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                        
                        Text(isCompleted ? "Completed" : "Mark as Complete")
                            .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                    }
                    .foregroundColor(isCompleted ? .white : StyleGuide.mainBrown)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isCompleted ? StyleGuide.gold : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(StyleGuide.gold, lineWidth: 2)
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal, StyleGuide.spacing.xl)
                .padding(.vertical, StyleGuide.spacing.md)
                .background(StyleGuide.backgroundBeige)
            }
            .fullScreenCover(isPresented: $showStories) {
                SessionStoriesView(session: session, unitTitle: unitTitle)
            }
            .task {
                // Load verses on appear
                loadVerses()
            }
        }
    }
    
    private func loadVerses() {
        for passage in session.passages {
            let verses = VerseRetriever.fetchVerses(reference: passage)
            loadedVerses[passage] = verses
        }
    }
    
    private func toggleComplete() {
        isCompleted.toggle()
        // TODO: Save completion to database
        print("Session \(session.id) marked as \(isCompleted ? "complete" : "incomplete")")
    }
}

struct ContentSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(StyleGuide.merriweather(size: 18, weight: .bold))
                    .foregroundColor(StyleGuide.mainBrown)
            }
            
            content
        }
        .padding(StyleGuide.spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

