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

    private init() {
        loadSettings()
    }

    func loadSettings() {
        if let savedSources = UserDefaults.standard.stringArray(forKey: "musicSources") {
            self.musicSources = savedSources
        }
    }

    func saveSettings() {
        UserDefaults.standard.set(self.musicSources, forKey: "musicSources")
    }
}
