//
//  RunDJApp.swift
//  RunDJ
//
//  Created on 5/15/25.
//

import SwiftUI
import Sentry

import SwiftData
import os.log

/// Main application entry point
@main
struct RunDJApp: App {
    
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    private let logger = Logger(subsystem: "com.rundj.RunDJ", category: "App")
    
    init() {
        logger.info("RunDJApp initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            BPMView()
                .environmentObject(SettingsManager.shared)
                .preferredColorScheme(.dark) // Force dark mode
                .onOpenURL { url in
                    logger.info("Received URL: \(url)")
                    
                    // Check if this is a Spotify callback
                    if url.absoluteString.contains("callback") {
                        // Handle Spotify auth callbacks
                        SpotifyManager.shared.handleURL(url)
                    } else if url.scheme == "rundj" {
                        // Handle Live Activity deep links
                        LiveActivityManager.shared.handleDeepLink(url)
                    } else {
                        // Default to Spotify for any other URLs
                        SpotifyManager.shared.handleURL(url)
                    }
                }
        }
    }

/// Application delegate for handling app lifecycle events
class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger(subsystem: "com.rundj.RunDJ", category: "AppDelegate")
    
    override init() {
        super.init()
        logger.info("AppDelegate initialized")
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        SentrySDK.start { options in
            options.dsn = Configuration.sentryDSN
            options.debug = true // Enabled debug when first installing is always helpful

            // Adds IP for users.
            // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
            options.sendDefaultPii = true

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0

            // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
            options.configureProfiling = {
                $0.sessionSampleRate = 1.0 // We recommend adjusting this value in production.
                $0.lifecycle = .trace
            }

             options.attachScreenshot = true
             options.attachViewHierarchy = true
        }

        logger.info("Application finished launching")
        return true
    }
}
}
