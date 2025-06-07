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
            return "Getting Started"
        case .runningView:
            return "Running with RunDJ"
        case .settingsView:
            return "Music Sources"
        }
    }
}

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    var context: HelpContext
    
    init(context: HelpContext = .bpmView) {
        self.context = context
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.rundjBackground
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 16) {
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
                .padding(.bottom, 20)
            }
            .navigationTitle(context.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.rundjMusicGreen)
                }
            }
        }
    }
    
    private var bpmHelpContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpSection(
                title: "What is BPM?",
                icon: "music.note",
                content: "BPM (beats per minute) is the measure of a song's tempo. RunDJ matches songs to your running rhythm using this measurement.",
                isMusic: true
            )
            
            HelpSection(
                title: "Auto BPM Detection",
                icon: "figure.run",
                content: "Start running and RunDJ will automatically detect your cadence. It takes a few seconds to measure your steps per minute, so keep on running if you still see 0."
            )
            
            HelpSection(
                title: "Manual BPM",
                icon: "slider.horizontal.3",
                content: "Already know your pace? Set a custom BPM between 100-200."
            )
        }
    }
    
    private var runningHelpContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HelpSection(
                    title: "Spotify Connection",
                    icon: "music.note.house",
                    content: "Connect your Spotify account to play music. On the first time you connect to Spotify, RunDJ will take a few minutes to process all your Spotify data. Click the refresh button to refetch songs after your data is processed. Due to the limitations of iOS, if playback pauses for 30 seconds, Spotify will automatically disconnect and you will have to reconnect again.",
                    isMusic: true
                )
                
                HelpSection(
                    title: "Queueing Algorithm",
                    icon: "list.bullet.indent",
                    content: "RunDJ uses the Spotify queue to queue your music. However, because Spotify does not offer an API to clear the queue, RunDJ manually clears your queue before each run by queueing a dummy song, and skipping until that song is reached. This is why you may see many songs flash across the now playing view before your songs are queued.",
                    isMusic: true
                )
                
                HelpSection(
                    title: "Music Controls",
                    icon: "hand.thumbsup",
                    content: "• Thumbs up: Like songs to improve recommendations\n• Thumbs down: Skip and never play again\n• Save playlist: Export your run's music to Spotify.",
                    isMusic: true
                )
                
                HelpSection(
                    title: "Run Tracking",
                    icon: "figure.run",
                    content: "Track distance, pace, time, and your current steps per minute. Your pace shows your average for the entire run."
                )
                
                HelpSection(
                    title: "Settings",
                    icon: "gearshape",
                    content: "Tap the gear icon to customize your RunDJ experience."
                )
            }
        }
        .scrollIndicators(.hidden)
    }
    
    private var settingsHelpContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpSection(
                title: "Choosing Sources",
                icon: "music.note.list",
                content: "Balance is key: too few sources may limit variety, while too many might dilute your preferences.",
                isMusic: true
            )
            
            HelpSection(
                title: "Top tracks and artists",
                icon: "square.stack.3d.up",
                content: "Top tracks/artists means your most listened to songs/artists according to Spotify.",
                isMusic: true
            )
            
            HelpSection(
                title: "Pro Tip",
                icon: "lightbulb",
                content: "For the best recommendations, select all sources except for followed and top artist's singles (artists have a lot of random singles in the Spotify database, and smaller artists often tag popular artists in their own songs for more exposure)."
            )
        }
    }
}

struct HelpSection: View {
    let title: String
    let icon: String
    let content: String
    var isMusic: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isMusic ? .rundjMusicGreen : .rundjAccent)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.rundjTextPrimary)
            }
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.rundjTextSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.rundjCardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    HelpView(context: .bpmView)
}
