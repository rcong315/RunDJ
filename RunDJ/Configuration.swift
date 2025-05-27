//
//  Configuration.swift
//  RunDJ
//
//  Configuration management for sensitive URLs and settings
//

import Foundation

struct Configuration {
    
    // MARK: - Server Configuration
    
    /// Base URL for the RunDJ API server
    static var serverBaseURL: String {
        #if DEBUG
        return Bundle.main.object(forInfoDictionaryKey: "SERVER_BASE_URL_DEBUG") as? String ?? "http://localhost:8000"
        #else
        return Bundle.main.object(forInfoDictionaryKey: "SERVER_BASE_URL_RELEASE") as? String ?? ""
        #endif
    }
    
    // MARK: - Sentry Configuration
    
    /// Sentry DSN for error reporting
    static var sentryDSN: String? {
        return Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String
    }
    
    // MARK: - Validation
    
    /// Validates that all required configuration values are present
    static func validateConfiguration() -> Bool {
        guard !serverBaseURL.isEmpty else {
            print("Configuration Error: SERVER_BASE_URL not set")
            return false
        }
        
        print("Configuration validated successfully")
        print("Server URL: \(serverBaseURL)")
        return true
    }
}
