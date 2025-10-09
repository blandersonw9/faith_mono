//
//  CustomStudyDetailView.swift
//  faith
//
//  Detail view for custom Bible study
//

import SwiftUI

struct CustomStudyDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var customStudyManager: CustomStudyManager
    let study: CustomStudy
    
    var body: some View {
        NavigationStack {
            ZStack {
                StyleGuide.backgroundBeige
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: StyleGuide.spacing.xl) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(study.title)
                                .font(StyleGuide.merriweather(size: 28, weight: .bold))
                                .foregroundColor(StyleGuide.mainBrown)
                            
                            if !study.description.isEmpty {
                                Text(study.description)
                                    .font(StyleGuide.merriweather(size: 15, weight: .medium))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.7))
                            }
                        }
                        .padding(.top, StyleGuide.spacing.lg)
                        
                        // Progress Overview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Progress")
                                .font(StyleGuide.merriweather(size: 18, weight: .bold))
                                .foregroundColor(StyleGuide.mainBrown)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(study.completedUnits) of \(study.totalUnits)")
                                        .font(StyleGuide.merriweather(size: 32, weight: .bold))
                                        .foregroundColor(StyleGuide.gold)
                                    
                                    Text("units completed")
                                        .font(StyleGuide.merriweather(size: 14, weight: .medium))
                                        .foregroundColor(StyleGuide.mainBrown.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                // Progress ring
                                ZStack {
                                    Circle()
                                        .stroke(StyleGuide.mainBrown.opacity(0.1), lineWidth: 8)
                                        .frame(width: 80, height: 80)
                                    
                                    Circle()
                                        .trim(from: 0, to: CGFloat(study.progressPercentage))
                                        .stroke(StyleGuide.gold, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                        .frame(width: 80, height: 80)
                                        .rotationEffect(.degrees(-90))
                                    
                                    Text("\(Int(study.progressPercentage * 100))%")
                                        .font(StyleGuide.merriweather(size: 16, weight: .bold))
                                        .foregroundColor(StyleGuide.mainBrown)
                                }
                            }
                            .padding(StyleGuide.spacing.md)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        
                        // Units List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Study Units")
                                .font(StyleGuide.merriweather(size: 18, weight: .bold))
                                .foregroundColor(StyleGuide.mainBrown)
                            
                            if study.units.isEmpty {
                                Text("Loading units...")
                                    .font(StyleGuide.merriweather(size: 14, weight: .medium))
                                    .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                                    .padding()
                            } else {
                                ForEach(study.units.sorted(by: { $0.unitIndex < $1.unitIndex })) { unit in
                                    StudyUnitRow(unit: unit)
                                }
                            }
                        }
                        
                        Spacer()
                            .frame(height: 60)
                    }
                    .padding(.horizontal, StyleGuide.spacing.xl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Custom Study")
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

struct StudyUnitRow: View {
    let unit: StudyUnit
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Unit header
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    // Unit number badge
                    ZStack {
                        Circle()
                            .fill(unit.isCompleted ? StyleGuide.gold : StyleGuide.mainBrown.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        if unit.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(unit.unitIndex + 1)")
                                .font(StyleGuide.merriweather(size: 16, weight: .bold))
                                .foregroundColor(StyleGuide.mainBrown)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(unit.title)
                            .font(StyleGuide.merriweather(size: 15, weight: .semibold))
                            .foregroundColor(StyleGuide.mainBrown)
                            .lineLimit(2)
                        
                        HStack(spacing: 8) {
                            Text("\(unit.sessions.count) session\(unit.sessions.count == 1 ? "" : "s")")
                                .font(StyleGuide.merriweather(size: 12, weight: .medium))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                            
                            Text("•")
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.3))
                            
                            Text("\(unit.estimatedMinutes) min")
                                .font(StyleGuide.merriweather(size: 12, weight: .medium))
                                .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                }
                .padding(StyleGuide.spacing.md)
                .background(Color.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // Expanded sessions
            if isExpanded && !unit.sessions.isEmpty {
                VStack(spacing: 8) {
                    ForEach(unit.sessions.sorted(by: { $0.sessionIndex < $1.sessionIndex })) { session in
                        SessionRow(session: session, unitTitle: unit.title)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

struct SessionRow: View {
    @EnvironmentObject var customStudyManager: CustomStudyManager
    let session: StudySession
    let unitTitle: String
    @State private var showSessionDetail = false
    
    var body: some View {
        Button(action: { showSessionDetail = true }) {
            HStack(spacing: 12) {
                // Completion indicator
                Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(session.isCompleted ? StyleGuide.gold : StyleGuide.mainBrown.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.title)
                        .font(StyleGuide.merriweather(size: 14, weight: .medium))
                        .foregroundColor(StyleGuide.mainBrown)
                    
                    Text(session.passages.joined(separator: ", "))
                        .font(StyleGuide.merriweather(size: 11, weight: .medium))
                        .foregroundColor(StyleGuide.mainBrown.opacity(0.5))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(StyleGuide.mainBrown.opacity(0.3))
            }
            .padding(StyleGuide.spacing.sm)
            .background(StyleGuide.backgroundBeige)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSessionDetail) {
            SessionDetailView(session: session, unitTitle: unitTitle)
                .environmentObject(customStudyManager)
        }
    }
}

