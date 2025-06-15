//
//  SettingsManager.swift
//  RunDJ
//
//  Created by Richard Cong on 5/15/25.
//

import SwiftUI

class SettingsManager: ObservableObject {
    
    static let shared = SettingsManager()

    @Published var musicSources: [String] = ["top_tracks", "saved_tracks", "playlists", "top_artists_top_tracks", "top_artists_albums", "followed_artists_top_tracks", "followed_artists_albums"]
    @Published var lastBPM: Double = 160.0
    @Published var useMetricUnits: Bool = false

    private init() {
        loadSettings()
    }

    func loadSettings() {
        if let savedSources = UserDefaults.standard.stringArray(forKey: "musicSources") {
            self.musicSources = savedSources
        }
        
        let savedBPM = UserDefaults.standard.double(forKey: "lastManualBPM")
        if savedBPM >= 100.0 && savedBPM <= 200.0 {
            self.lastBPM = savedBPM
        } else {
            self.lastBPM = 160.0
        }
        
        self.useMetricUnits = UserDefaults.standard.bool(forKey: "useMetricUnits")
    }

    func saveSettings() {
        UserDefaults.standard.set(self.musicSources, forKey: "musicSources")
        UserDefaults.standard.set(self.lastBPM, forKey: "lastBPM")
        UserDefaults.standard.set(self.useMetricUnits, forKey: "useMetricUnits")
    }
}
