//
//  RunDJApp.swift
//  RunDJ
//
//  Created by Richard Cong on 2/8/25.
//

import SwiftUI
import SwiftData

@main
struct RunDJApp: App {
    
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    init() {
        print("RunDJApp initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print("onOpenURL received: \(url)")
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
            print("Application did finish launching")
            return true
        }
        
        func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
            print("Received URL: \(url)")
            let handled = SpotifyManager.shared.sessionManager.application(app, open: url, options: options)
//            SpotifyManager.shared.handleURL(url)
            print("URL handled by Spotify")
            return true
        }
        
        func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
            print("Continuing user activity: \(userActivity)")
            if let url = userActivity.webpageURL {
                print("Received universal link URL: \(url)")
                let handled = SpotifyManager.shared.sessionManager.application(application, open: url)
                print("Universal link handled by Spotify: \(handled)")
                return handled
            }
            return false
        }
    }
}
