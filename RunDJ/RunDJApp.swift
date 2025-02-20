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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    SpotifyManager.shared.handleAuthCallback(url: url)
                }
        }
    }
}
