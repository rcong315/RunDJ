//
//  RunningView.swift
//  RunDJ
//
//  Created by Richard Cong on 2/8/25.
//

import SwiftUI
import SwiftData
import UIKit

struct RunningView: View {
    @StateObject private var pedometerManager = PedometerManager.shared
    @StateObject private var spotifyManager = SpotifyManager.shared
    @StateObject private var rundjService = RunDJService()
    
    @State private var showSpotifyError = false
    @State private var errorMessage = ""
    @State private var showingHelp = false
    @State private var showCopiedNotification = false
    
    @State private var token = ""
    @State private var songs = []
    
    var bpm: Double
    var sources: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: {
                    showingHelp = true
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .padding()
            }
            
            Text("BPM: \(bpm)")
                .font(.title)
            
            Button(action: {
                
            }) {
                Text("Play Music")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: {
                spotifyManager.playPause()
            }) {
                Text("Play/Pause")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: {
                spotifyManager.skipToNext()
            }) {
                Text("Next Song")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            VStack() {
                Text("Access Token")
                    .font(.system(size: 30))
                Text(spotifyManager.getAccessToken()?.replacingOccurrences(of: "-", with: "\u{2011}") ?? "")
                    .font(.system(size: 10))
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = String(pedometerManager.stepsPerMinute)
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                    .onTapGesture {
                        UIPasteboard.general.string = String(pedometerManager.stepsPerMinute)
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        showCopiedNotification = true
                    }
                
                Text("Tap to copy")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .overlay(
                Group {
                    if showCopiedNotification {
                        VStack {
                            Text("Copied to clipboard")
                                .padding()
                                .background(Color.blue.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(radius: 3)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.5).delay(1.5)) {
                                showCopiedNotification = false
                            }
                        }
                    }
                }
            )
        }
        .onAppear {
            token = spotifyManager.getAccessToken() ?? ""
            rundjService.getSongsByBPM(accessToken: token, bpm: bpm, sources: sources) { fetchedSongs in
                if !songs.isEmpty {
                    spotifyManager.queue(songs: fetchedSongs)
                }
            }
        }
        .onChange(of: spotifyManager.connectionState) { _, newState in
            switch newState {
            case .error(let message):
                errorMessage = message
                showSpotifyError = true
            default:
                break
            }
        }
        .alert(isPresented: $showSpotifyError) {
            return Alert(
                title: Text("Spotify Connection Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
    }
}

#Preview {
    RunningView(bpm: 160, sources: [])
}
