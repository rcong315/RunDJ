//
//  HelpView.swift
//  RunDJ
//
//  Created by Richard Cong on 2/23/25.
//

import SwiftUI

// Define an enum for different help contexts
enum HelpContext {
    case bpmView
    case runningView
    case settingsView
    
    var title: String {
        switch self {
        case .bpmView:
            return "BPM"
        case .runningView:
            return "Start Running"
        case .settingsView:
            return "Music Source Settings"
        }
    }
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    var context: HelpContext
    
    // Initialize with a default context if none is provided
    init(context: HelpContext = .bpmView) {
        self.context = context
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Show different content based on the context
                    switch context {
                    case .bpmView:
                        bpmHelpContent
                    case .runningView:
                        runningHelpContent
                    case .settingsView:
                        settingsHelpContent
                    }
                }
                .padding()
            }
            .navigationTitle(context.title)
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
    
    
    private var bpmHelpContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HelpSection(title: "What is BPM?", content: """
                BPM (beats per minute) is the the measure of a song's tempo. 
                RunDJ uses this measurement to filter songs that will match you running rhythm.
                """)
            
            HelpSection(title: "Tailored BPM", content: """
                RunDJ can choose your BPM for you. Just start running and give it a few seconds to detect your cadence. 
                Click start in the top section to lock in your BPM as your steps per minute.
                """)
            
            HelpSection(title: "Custom BPM", content: """
                If you know your regular running pace, or you want to set a custom BPM, you can do so as well in the bottom section. 
                The allowed range is 100-200 BPM.
                """)
        }
    }
    
    private var runningHelpContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HelpSection(title: "Spotify", content: """
                RunDJ uses Spotify to play music and control playback. 
                Click the connect button to give RunDJ access to your Spotify listening data and playback controls.
                If music is paused for 30 seconds straight, your connection with Spotify will be lost and you will have to reconnect in order to play music. 
                Unfortunately this is a limitation of the Spotify app and iOS background app management, so nothing can be done about this.
                """)
            
            HelpSection(title: "Feedback Controls", content: """
                • Tap the thumbs up icon if you like the current song - this will improve your recommendations
                • Tap the thumbs down icon to skip the song and mark it as disliked, this song will not be played again
                """)
            
            HelpSection(title: "Run Tracking", content: """
                • Tap "Start Run" to begin tracking your run metrics (distance, pace, time)
                • "Pace" is your overall pace over the entire run
                • Tap "Stop Run" to end your run
                """)
            
            HelpSection(title: "Settings", content: """
                • Tap the gear icon to access music source settings
                • Changes to music sources will affect the next batch of songs queued
                """)
        }
    }
    
    private var settingsHelpContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HelpSection(title: "Music Sources", content: """
                Select what music sources you would want RunDJ to look through. 
                Selecting too few sources might produce too few tracks. 
                Selecting too many might produce a tracklist less tailored to your tastes.
                """)

            HelpSection(title: "Source Options", content: """
                • Top tracks: Songs you listen to most frequently
                • Saved tracks: Songs you've liked on Spotify
                • Playlists: Songs from your saved and followed playlists
                • Top artists' tracks: Songs from artists you listen to most frequently
                • Followed artists' content: Songs from artists you follow
                • Saved albums: Songs from albums you've saved
                """)
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
