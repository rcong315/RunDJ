//
//  RunDJApp.swift
//  RunDJ
//
//  Created by Richard Cong on 2/8/25.
//

import SwiftUI
import SwiftData

// TODO: os.log

@main
struct RunDJApp: App {
    
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    init() {
        print("RunDJApp initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            BPMView()
                .onOpenURL { url in
                    print("onOpenURL received")
                    SpotifyManager.shared.handleURL(url)
                }
        }
    }
    
    class AppDelegate: NSObject, UIApplicationDelegate {
        override init() {
            super.init()
            print("AppDelegate initialized")
        }
        
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            print("Application finished launching")
            return true
        }
    }
}
