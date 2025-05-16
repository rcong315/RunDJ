//
//  RunDJApp.swift
//  RunDJ
//
//  Created on 5/15/25.
//

import SwiftUI
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
                .onOpenURL { url in
                    logger.info("Received URL: \(url)")
                    SpotifyManager.shared.handleURL(url)
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
        logger.info("Application finished launching")
        return true
    }
}
}
