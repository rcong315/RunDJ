//
//  HelpView.swift
//  RunDJ
//
//  Created by Richard Cong on 2/23/25.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HelpSection(title: "Getting Started", content: """
                        1. Tap 'Connect to Spotify' to link your Spotify account> You will be brought to the Spotify app, please click agree to allow Run DJ to control playback.
                        2. Start walking or running, the app will detect your cadence in steps per minute.
                        3. Once you see a reading in the 'Steps Per Minute' field, tap 'Play Music' to start a playlist that matches the beat to your cadence. Your steps per minute will be rounded to the nearest multiple of 5. Currently only 130-190 BPM playlists are supported.
                        """)
                    
                    HelpSection(title: "Features", content: """
                        • Automatic pace detection
                        • Tempo-matched music selection based off of your favorite tracks, artists, and playlists
                        • Skip songs with 'Next Song' button
                        """)
                    
                    HelpSection(title: "Tips", content: """
                        • Make sure Spotify is installed and you're logged in
                        • Please email any feedback, suggestions, and concerns to richardcong635@gmail.com
                        """)
                }
                .padding()
            }
            .navigationTitle("How to Use RunDJ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HelpSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}
