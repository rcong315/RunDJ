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
    
    static var serverAPIKey: String {
        return Bundle.main.object(forInfoDictionaryKey: "SERVER_API_KEY") as? String ?? ""
    }
    
    // MARK: - Sentry Configuration
    
    /// Sentry DSN for error reporting
    static var sentryDSN: String? {
        return Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String
    }
}
