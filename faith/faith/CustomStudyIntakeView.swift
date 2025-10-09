//
//  CustomStudyIntakeView.swift
//  faith
//
//  Intake flow for custom Bible study generation
//

import SwiftUI

struct CustomStudyIntakeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var customStudyManager: CustomStudyManager
    @State private var currentStep: Int = 0
    @State private var intakeState = CustomStudyIntakeState()
    @State private var isGenerating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let totalSteps = 6
    
    var body: some View {
        NavigationStack {
            ZStack {
                StyleGuide.backgroundBeige
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                        .padding(.horizontal, StyleGuide.spacing.xl)
                        .padding(.top, StyleGuide.spacing.md)
                    
                    // Content
                    TabView(selection: $currentStep) {
                        Step1GoalsView(intakeState: $intakeState)
                            .tag(0)
                        
                        Step2TopicsView(intakeState: $intakeState)
                            .tag(1)
                        
                        Step3TimeView(intakeState: $intakeState)
                            .tag(2)
                        
                        Step4TranslationView(intakeState: $intakeState)
                            .tag(3)
                        
                        Step5ReadingLevelView(intakeState: $intakeState)
                            .tag(4)
                        
                        Step6DiscussionView(intakeState: $intakeState)
                            .tag(5)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Navigation buttons
                    HStack(spacing: StyleGuide.spacing.md) {
                        if currentStep > 0 {
                            Button(action: { withAnimation { currentStep -= 1 } }) {
                                Text("Back")
                                    .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                                    .foregroundColor(StyleGuide.mainBrown)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(StyleGuide.mainBrown.opacity(0.3), lineWidth: 1)
                                    )
                                    .cornerRadius(12)
                            }
                        }
                        
                        Button(action: handleNext) {
                            HStack(spacing: 8) {
                                Text(currentStep == totalSteps - 1 ? "Generate Study" : "Next")
                                    .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                                
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(canProceed ? StyleGuide.mainBrown : StyleGuide.mainBrown.opacity(0.3))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .disabled(!canProceed || isGenerating)
                    }
                    .padding(.horizontal, StyleGuide.spacing.xl)
                    .padding(.bottom, StyleGuide.spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Custom Bible Study")
                        .font(StyleGuide.merriweather(size: 18, weight: .semibold))
                        .foregroundColor(StyleGuide.mainBrown)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(StyleGuide.mainBrown)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !intakeState.selectedGoals.isEmpty
        case 1: return !intakeState.selectedTopics.isEmpty
        case 2, 3, 4, 5: return true
        default: return false
        }
    }
    
    private func handleNext() {
        if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            // Generate study
            Task {
                await generateStudy()
            }
        }
    }
    
    private func generateStudy() async {
        isGenerating = true
        do {
            try await customStudyManager.savePreferencesAndGenerate(intakeState)
            // Dismiss immediately - generation continues in background
            isGenerating = false
            dismiss()
        } catch {
            errorMessage = "Failed to start study generation: \(error.localizedDescription)"
            showError = true
            isGenerating = false
        }
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(StyleGuide.mainBrown.opacity(0.1))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [StyleGuide.gold, StyleGuide.gold.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * CGFloat(currentStep + 1) / CGFloat(totalSteps), height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Step 1: Goals

struct Step1GoalsView: View {
    @Binding var intakeState: CustomStudyIntakeState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StyleGuide.spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What are your goals?")
                        .font(StyleGuide.merriweather(size: 24, weight: .bold))
                        .foregroundColor(StyleGuide.mainBrown)
                    
                    Text("Choose one or more goals for your Bible study")
                        .font(StyleGuide.merriweather(size: 14, weight: .medium))
                        .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                }
                .padding(.top, StyleGuide.spacing.xl)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: StyleGuide.spacing.md) {
                    ForEach(StudyGoal.allCases) { goal in
                        GoalCard(
                            goal: goal,
                            isSelected: intakeState.selectedGoals.contains(goal)
                        ) {
                            if intakeState.selectedGoals.contains(goal) {
                                intakeState.selectedGoals.remove(goal)
                            } else {
                                intakeState.selectedGoals.insert(goal)
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
}

struct GoalCard: View {
    let goal: StudyGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: goal.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? StyleGuide.gold : StyleGuide.mainBrown.opacity(0.6))
                
                Text(goal.rawValue)
                    .font(StyleGuide.merriweather(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? StyleGuide.mainBrown : StyleGuide.mainBrown.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(isSelected ? StyleGuide.gold.opacity(0.15) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? StyleGuide.gold : StyleGuide.mainBrown.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: Topics

struct Step2TopicsView: View {
    @Binding var intakeState: CustomStudyIntakeState
    @State private var customTopicText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StyleGuide.spacing.lg) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose your topics")
                        .font(StyleGuide.merriweather(size: 24, weight: .bold))
                        .foregroundColor(StyleGuide.mainBrown)
                    
                    Text("Select topics you'd like to explore")
                        .font(StyleGuide.merriweather(size: 14, weight: .medium))
                        .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                }
                .padding(.top, StyleGuide.spacing.xl)
                
                // Predefined topics
                FlowLayout(spacing: 8) {
                    ForEach(StudyTopic.allCases) { topic in
                        TopicChip(
                            topic: topic,
                            isSelected: intakeState.selectedTopics.contains(topic)
                        ) {
                            if intakeState.selectedTopics.contains(topic) {
                                intakeState.selectedTopics.remove(topic)
                            } else {
                                intakeState.selectedTopics.insert(topic)
                            }
                        }
                    }
                }
                
                // Custom topics section
                if !intakeState.customTopics.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your custom topics:")
                            .font(StyleGuide.merriweather(size: 12, weight: .semibold))
                            .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                        
                        FlowLayout(spacing: 8) {
                            ForEach(intakeState.customTopics, id: \.self) { customTopic in
                                CustomTopicChip(
                                    text: customTopic,
                                    onRemove: {
                                        intakeState.customTopics.removeAll { $0 == customTopic }
                                    }
                                )
                            }
                        }
                    }
                }
                
                // Add custom topic input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add your own topic:")
                        .font(StyleGuide.merriweather(size: 12, weight: .semibold))
                        .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                    
                    HStack(spacing: 8) {
                        TextField("e.g., Parenting, Spiritual Warfare", text: $customTopicText)
                            .font(StyleGuide.merriweather(size: 14, weight: .medium))
                            .foregroundColor(StyleGuide.mainBrown)
                            .padding(12)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isTextFieldFocused ? StyleGuide.gold : StyleGuide.mainBrown.opacity(0.2), lineWidth: 1)
                            )
                            .cornerRadius(8)
                            .focused($isTextFieldFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                addCustomTopic()
                            }
                        
                        Button(action: addCustomTopic) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(customTopicText.isEmpty ? StyleGuide.mainBrown.opacity(0.3) : StyleGuide.gold)
                        }
                        .disabled(customTopicText.isEmpty)
                    }
                }
                
                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal, StyleGuide.spacing.xl)
        }
        .scrollIndicators(.hidden)
    }
    
    private func addCustomTopic() {
        let trimmed = customTopicText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !intakeState.customTopics.contains(trimmed) {
            intakeState.customTopics.append(trimmed)
            customTopicText = ""
            isTextFieldFocused = false
        }
    }
}

struct TopicChip: View {
    let topic: StudyTopic
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(topic.rawValue)
                .font(StyleGuide.merriweather(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : StyleGuide.mainBrown)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? StyleGuide.mainBrown : Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? StyleGuide.mainBrown : StyleGuide.mainBrown.opacity(0.25), lineWidth: 1)
                )
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

struct CustomTopicChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(StyleGuide.merriweather(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(StyleGuide.gold)
        .cornerRadius(20)
    }
}

// MARK: - Step 3: Time

struct Step3TimeView: View {
    @Binding var intakeState: CustomStudyIntakeState
    
    let timeOptions = [7, 10, 15, 20, 25, 30]
    
    var body: some View {
        VStack(alignment: .leading, spacing: StyleGuide.spacing.xl) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Time per session")
                    .font(StyleGuide.merriweather(size: 24, weight: .bold))
                    .foregroundColor(StyleGuide.mainBrown)
                
                Text("How many minutes can you dedicate daily?")
                    .font(StyleGuide.merriweather(size: 14, weight: .medium))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
            }
            .padding(.top, StyleGuide.spacing.xl)
            
            VStack(spacing: StyleGuide.spacing.md) {
                ForEach(timeOptions, id: \.self) { time in
                    TimeOptionCard(
                        minutes: time,
                        isSelected: intakeState.minutesPerSession == time
                    ) {
                        intakeState.minutesPerSession = time
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, StyleGuide.spacing.xl)
    }
}

struct TimeOptionCard: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(minutes) minutes")
                        .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                        .foregroundColor(StyleGuide.mainBrown)
                    
                    Text(timeDescription)
                        .font(StyleGuide.merriweather(size: 12, weight: .medium))
                        .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(StyleGuide.gold)
                }
            }
            .padding(StyleGuide.spacing.md)
            .background(isSelected ? StyleGuide.gold.opacity(0.1) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? StyleGuide.gold : StyleGuide.mainBrown.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private var timeDescription: String {
        switch minutes {
        case 7: return "Quick devotional"
        case 10: return "Short and focused"
        case 15: return "Balanced study"
        case 20: return "In-depth reading"
        case 25: return "Comprehensive"
        case 30: return "Deep dive"
        default: return ""
        }
    }
}

// MARK: - Step 4: Translation

struct Step4TranslationView: View {
    @Binding var intakeState: CustomStudyIntakeState
    
    var body: some View {
        VStack(alignment: .leading, spacing: StyleGuide.spacing.xl) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Bible translation")
                    .font(StyleGuide.merriweather(size: 24, weight: .bold))
                    .foregroundColor(StyleGuide.mainBrown)
                
                Text("Which translation would you like to use?")
                    .font(StyleGuide.merriweather(size: 14, weight: .medium))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
            }
            .padding(.top, StyleGuide.spacing.xl)
            
            VStack(spacing: StyleGuide.spacing.md) {
                ForEach(StudyTranslation.allCases) { translation in
                    TranslationCard(
                        translation: translation,
                        isSelected: intakeState.selectedTranslation == translation
                    ) {
                        intakeState.selectedTranslation = translation
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, StyleGuide.spacing.xl)
    }
}

struct TranslationCard: View {
    let translation: StudyTranslation
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(translation.rawValue)
                        .font(StyleGuide.merriweather(size: 16, weight: .bold))
                        .foregroundColor(StyleGuide.mainBrown)
                    
                    Text(translation.displayName)
                        .font(StyleGuide.merriweather(size: 12, weight: .medium))
                        .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(StyleGuide.gold)
                }
            }
            .padding(StyleGuide.spacing.md)
            .background(isSelected ? StyleGuide.gold.opacity(0.1) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? StyleGuide.gold : StyleGuide.mainBrown.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 5: Reading Level

struct Step5ReadingLevelView: View {
    @Binding var intakeState: CustomStudyIntakeState
    
    var body: some View {
        VStack(alignment: .leading, spacing: StyleGuide.spacing.xl) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Reading level")
                    .font(StyleGuide.merriweather(size: 24, weight: .bold))
                    .foregroundColor(StyleGuide.mainBrown)
                
                Text("Choose the style that fits you best")
                    .font(StyleGuide.merriweather(size: 14, weight: .medium))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
            }
            .padding(.top, StyleGuide.spacing.xl)
            
            VStack(spacing: StyleGuide.spacing.md) {
                ForEach(ReadingLevel.allCases, id: \.self) { level in
                    ReadingLevelCard(
                        level: level,
                        isSelected: intakeState.readingLevel == level
                    ) {
                        intakeState.readingLevel = level
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, StyleGuide.spacing.xl)
    }
}

struct ReadingLevelCard: View {
    let level: ReadingLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                        .foregroundColor(StyleGuide.mainBrown)
                    
                    Text(levelDescription)
                        .font(StyleGuide.merriweather(size: 12, weight: .medium))
                        .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(StyleGuide.gold)
                }
            }
            .padding(StyleGuide.spacing.md)
            .background(isSelected ? StyleGuide.gold.opacity(0.1) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? StyleGuide.gold : StyleGuide.mainBrown.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private var levelDescription: String {
        switch level {
        case .simple: return "Easy to understand, warm tone"
        case .conversational: return "Balanced approach"
        case .scholarly: return "In-depth, academic style"
        }
    }
}

// MARK: - Step 6: Discussion Questions

struct Step6DiscussionView: View {
    @Binding var intakeState: CustomStudyIntakeState
    
    var body: some View {
        VStack(alignment: .leading, spacing: StyleGuide.spacing.xl) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Final touch")
                    .font(StyleGuide.merriweather(size: 24, weight: .bold))
                    .foregroundColor(StyleGuide.mainBrown)
                
                Text("Would you like discussion questions?")
                    .font(StyleGuide.merriweather(size: 14, weight: .medium))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
            }
            .padding(.top, StyleGuide.spacing.xl)
            
            VStack(spacing: StyleGuide.spacing.md) {
                ToggleCard(
                    title: "Include discussion questions",
                    description: "Great for small groups or personal reflection",
                    isOn: $intakeState.includeDiscussionQuestions
                )
            }
            
            // Summary card
            VStack(alignment: .leading, spacing: StyleGuide.spacing.md) {
                Text("Your Study Summary")
                    .font(StyleGuide.merriweather(size: 18, weight: .bold))
                    .foregroundColor(StyleGuide.mainBrown)
                
                SummaryRow(label: "Goals", value: "\(intakeState.selectedGoals.count) selected")
                SummaryRow(label: "Topics", value: "\(intakeState.selectedTopics.count + intakeState.customTopics.count) selected")
                SummaryRow(label: "Time", value: "\(intakeState.minutesPerSession) min/day")
                SummaryRow(label: "Translation", value: intakeState.selectedTranslation.rawValue)
                SummaryRow(label: "Level", value: intakeState.readingLevel.displayName)
            }
            .padding(StyleGuide.spacing.md)
            .background(StyleGuide.gold.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding(.horizontal, StyleGuide.spacing.xl)
    }
}

struct ToggleCard: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(StyleGuide.merriweather(size: 16, weight: .semibold))
                    .foregroundColor(StyleGuide.mainBrown)
                
                Text(description)
                    .font(StyleGuide.merriweather(size: 12, weight: .medium))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(StyleGuide.gold)
        }
        .padding(StyleGuide.spacing.md)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(StyleGuide.mainBrown.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(StyleGuide.merriweather(size: 14, weight: .medium))
                .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(StyleGuide.merriweather(size: 14, weight: .semibold))
                .foregroundColor(StyleGuide.mainBrown)
        }
    }
}
