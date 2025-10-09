//
//  CustomStudyManager.swift
//  faith
//
//  Manager for custom Bible study generation and storage
//

import Foundation
import Supabase
import Combine

@MainActor
class CustomStudyManager: ObservableObject {
    @Published var currentStudy: CustomStudy?
    @Published var isLoading = false
    @Published var isGenerating = false
    @Published var error: String?
    
    private let supabaseClient: SupabaseClient
    
    init(supabaseClient: SupabaseClient) {
        self.supabaseClient = supabaseClient
    }
    
    // MARK: - Save Preferences and Trigger Generation
    
    func savePreferencesAndGenerate(_ intakeState: CustomStudyIntakeState) async throws {
        isLoading = true
        isGenerating = true
        error = nil
        
        do {
            // Get current user ID
            let session = try await supabaseClient.auth.session
            let userId = session.user.id
            
            // Create preferences object
            let preferences = intakeState.toPreferences(userId: userId)
            
            // Save preferences to database
            let savedPreferences: CustomStudyPreferences = try await supabaseClient
                .from("custom_study_preferences")
                .insert(preferences)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ Saved preferences: \(savedPreferences.id)")
            
            isLoading = false
            
            // Trigger study generation via Supabase Edge Function in background
            print("🚀 Triggering study generation...")
            Task.detached {
                do {
                    try await self.triggerStudyGenerationBackground(preferenceId: savedPreferences.id, userId: userId)
                    
                    // Fetch the newly generated study
                    try await self.fetchActiveStudy()
                    
                    await MainActor.run {
                        self.isGenerating = false
                    }
                    print("✅ Study generation complete and loaded!")
                } catch {
                    print("❌ Study generation failed: \(error)")
                    await MainActor.run {
                        self.isGenerating = false
                        self.error = error.localizedDescription
                    }
                }
            }
        } catch {
            isLoading = false
            isGenerating = false
            self.error = error.localizedDescription
            throw error
        }
    }
    
    private func triggerStudyGenerationBackground(preferenceId: UUID, userId: UUID) async throws {
        let session = try await supabaseClient.auth.session
        let accessToken = session.accessToken
        
        // Get the Supabase URL and construct Edge Function endpoint
        let functionUrl = "\(Config.supabaseURL)/functions/v1/generate-custom-study"
        
        guard let url = URL(string: functionUrl) else {
            throw CustomStudyError.studyGenerationFailed("Invalid function URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120 // 2 minutes timeout
        
        let body: [String: String] = [
            "preference_id": preferenceId.uuidString,
            "user_id": userId.uuidString
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Create custom URLSession with longer timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120 // 2 minutes
        config.timeoutIntervalForResource = 120 // 2 minutes
        let urlSession = URLSession(configuration: config)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CustomStudyError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Study generation failed: \(errorMessage)")
            throw CustomStudyError.studyGenerationFailed(errorMessage)
        }
        
        // Parse response
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let studyId = json["study_id"] as? String {
            print("✅ Study generated successfully: \(studyId)")
        }
    }
    
    // MARK: - Fetch Active Study
    
    func fetchActiveStudy() async throws {
        print("📚 Starting fetchActiveStudy...")
        isLoading = true
        error = nil
        
        do {
            let session = try await supabaseClient.auth.session
            let userId = session.user.id
            print("📚 User ID for study fetch: \(userId)")
            
            // Fetch the active study for the user
            struct StudyWithRelations: Decodable {
                let id: UUID
                let userId: UUID
                let preferenceId: UUID
                let title: String
                let description: String
                let totalUnits: Int
                let completedUnits: Int
                let isActive: Bool
                let createdAt: String
                let updatedAt: String
                let units: [StudyUnit]
                
                enum CodingKeys: String, CodingKey {
                    case id
                    case userId = "user_id"
                    case preferenceId = "preference_id"
                    case title
                    case description
                    case totalUnits = "total_units"
                    case completedUnits = "completed_units"
                    case isActive = "is_active"
                    case createdAt = "created_at"
                    case updatedAt = "updated_at"
                    case units
                }
            }
            
            let studies: [StudyWithRelations] = try await supabaseClient
                .from("custom_studies")
                .select("""
                    *,
                    units:custom_study_units(
                        *,
                        sessions:custom_study_sessions(*)
                    )
                """)
                .eq("user_id", value: userId.uuidString)
                .eq("is_active", value: true)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value
            
            // Convert to CustomStudy
            let customStudies = studies.map { study in
                CustomStudy(
                    id: study.id,
                    userId: study.userId,
                    preferenceId: study.preferenceId,
                    title: study.title,
                    description: study.description,
                    totalUnits: study.totalUnits,
                    completedUnits: study.completedUnits,
                    isActive: study.isActive,
                    createdAt: study.createdAt,
                    updatedAt: study.updatedAt,
                    units: study.units
                )
            }
            
            await MainActor.run {
                currentStudy = customStudies.first
                isLoading = false
            }
            
            if let study = customStudies.first {
                print("✅ Found active study: \(study.title) with \(study.units.count) units")
            } else {
                print("ℹ️ No active study found")
            }
        } catch {
            await MainActor.run {
                isLoading = false
                self.error = error.localizedDescription
            }
            print("❌ fetchActiveStudy error: \(error)")
            throw error
        }
    }
    
    // MARK: - Check if User Can Generate New Study
    
    func canGenerateNewStudy() async -> Bool {
        do {
            let session = try await supabaseClient.auth.session
            let userId = session.user.id
            
            // Check if there's an active incomplete study
            let studies: [CustomStudy] = try await supabaseClient
                .from("custom_studies")
                .select("*")
                .eq("user_id", value: userId.uuidString)
                .eq("is_active", value: true)
                .execute()
                .value
            
            if let study = studies.first {
                // User can only generate if current study is completed
                return study.completedUnits >= study.totalUnits
            }
            
            // No active study, user can generate
            return true
        } catch {
            print("❌ Error checking study status: \(error)")
            return false
        }
    }
}

// MARK: - Custom Study Errors

enum CustomStudyError: LocalizedError {
    case notAuthenticated
    case studyGenerationFailed(String)
    case networkError
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to generate a custom study."
        case .studyGenerationFailed(let message):
            return "Failed to generate study: \(message)"
        case .networkError:
            return "Network error. Please check your connection."
        case .invalidData:
            return "Invalid data received from server."
        }
    }
}

