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
                
                ScrollView(showsIndicators: false) {
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
                content: "BPM (beats per minute) measures a song's tempo. RunDJ matches songs to your running rhythm using this measurement.",
                isMusic: true
            )
            
            HelpSection(
                title: "Auto BPM Detection",
                icon: "figure.run",
                content: "Start running and RunDJ will automatically detect your cadence. It takes just a few seconds to measure your steps per minute and find matching songs."
            )
            
            HelpSection(
                title: "Manual BPM",
                icon: "slider.horizontal.3",
                content: "Know your pace? Set a custom BPM between 100-200. Perfect for targeting specific training cadences or matching your favorite running tempo."
            )
        }
    }
    
    private var runningHelpContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HelpSection(
                title: "Spotify Connection",
                icon: "music.note.house",
                content: "Connect your Spotify account to play music. If playback pauses for 30+ seconds, you'll need to reconnect due to iOS limitations.",
                isMusic: true
            )
            
            HelpSection(
                title: "Music Controls",
                icon: "hand.thumbsup",
                content: "• Thumbs up: Like songs to improve recommendations\n• Thumbs down: Skip and never play again\n• Save playlist: Export your run's music to Spotify",
                isMusic: true
            )
            
            HelpSection(
                title: "Run Tracking",
                icon: "figure.run",
                content: "Track distance, pace, and time. Your pace shows your overall average for the entire run."
            )
            
            HelpSection(
                title: "Music Sources",
                icon: "gearshape",
                content: "Tap the gear icon to customize which music sources RunDJ searches. Changes apply to the next batch of songs."
            )
        }
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
                title: "Available Sources",
                icon: "square.stack.3d.up",
                content: "• Top & Saved tracks: Your favorites\n• Playlists: Curated collections\n• Artists' content: From your top and followed artists\n• Albums: Songs from saved albums",
                isMusic: true
            )
            
            HelpSection(
                title: "Pro Tip",
                icon: "lightbulb",
                content: "Start with 3-4 sources for the best balance of variety and personalization. You can always adjust based on results."
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
