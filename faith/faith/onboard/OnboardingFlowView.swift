//
//  OnboardingFlowView.swift
//  faith
//
//  Created on 10/1/25.
//

import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var currentPage: Int = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        ZStack {
            switch currentPage {
            case 0:
                OnboardingWelcomeView(onContinue: {
                    withAnimation {
                        currentPage = 1
                    }
                })
                .transition(.opacity)
            case 1:
                OnboardingGrowthView(onContinue: {
                    withAnimation {
                        currentPage = 2
                    }
                })
                .transition(.opacity)
            case 2:
                OnboardingLoadingView(onComplete: {
                    hasCompletedOnboarding = true
                })
                .transition(.opacity)
            default:
                EmptyView()
            }
        }
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AuthManager())
}

