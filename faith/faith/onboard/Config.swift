//
//  Config.swift
//  faith
//
//  Created by Blake Anderson on 9/24/25.
//

import Foundation

struct Config {
    // Supabase Configuration
    static let supabaseURL: String = {
        // First try to get from environment variable
        if let url = ProcessInfo.processInfo.environment["SUPABASE_URL"] {
            return url
        }
        // Fallback to hardcoded value (replace with your actual URL)
        return "https://ppkqyfcnwajfzhvnqxec.supabase.co"
    }()
    
    static let supabaseAnonKey: String = {
        // First try to get from environment variable
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
            return key
        }
        // Fallback to hardcoded value (replace with your actual key)
        return "sb_publishable_b0vFYtSgyESO0t5sYjYNDQ_-AF67jvX"
    }()
    
    // Google Sign-In Configuration
    static let googleClientID = "845381061349-h4c9jk0dr3gfjb97mpb64o4oiaasf70g.apps.googleusercontent.com"
    
    // Helper method to validate configuration
    static func validate() -> Bool {
        return !supabaseURL.contains("YOUR_SUPABASE_URL") && 
               !supabaseAnonKey.contains("YOUR_SUPABASE_ANON_KEY")
    }
    
    // Helper method to log configuration status (for debugging)
    static func logConfigStatus() {
        print("🔧 Configuration Status:")
        print("   Supabase URL: \(supabaseURL.isEmpty ? "❌ Not set" : "✅ Set")")
        print("   Supabase Key: \(supabaseAnonKey.isEmpty ? "❌ Not set" : "✅ Set")")
        print("   Google Client ID: \(googleClientID.isEmpty ? "❌ Not set" : "✅ Set")")
        print("   Configuration Valid: \(validate() ? "✅" : "❌")")
    }
}