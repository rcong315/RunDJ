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
    @StateObject private var rundjService = RunDJService.shared
    @StateObject private var runManager = RunManager()
    @StateObject private var runningStatsManager = RunningStatsManager()
    @EnvironmentObject var settingsManager: SettingsManager
    
    @State private var showSpotifyError = false
    @State private var errorMessage = ""
    @State private var showingHelp = false
    @State private var showCopiedNotification = false
    @State private var isRunning = false
    @State private var showingSettingsModal = false
    
    
    var bpm: Double
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Button(action: {
                switch spotifyManager.connectionState {
                case .disconnected:
                    initiateSession()
                case .error:
                    initiateSession()
                default:
                    break
                }
            }) {
                Text(buttonText)
                    .padding()
                    .background(buttonColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            Text("Status: \(connectionStateText)")
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
            
            Text("Set BPM: \(bpm)")
                .font(.title3)
            
            Text("Playing: \(spotifyManager.currentlyPlaying) \n BPM: \(spotifyManager.currentBPM)")
                .font(.title3)
                .padding()
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(spacing: 20) {
                HStack(spacing: 40) {
                    
                    Button(action: {
                        spotifyManager.rewind()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        spotifyManager.isPlaying ? spotifyManager.pause() : spotifyManager.resume()
                    }) {
                        Image(systemName: spotifyManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.green)
                    }
                    
                    // --- Next Button ---
                    Button(action: {
                        spotifyManager.skipToNext()
                    }) {
                        Image(systemName: "forward.fill") // SF Symbol for forward/next
                            .font(.title)
                            .foregroundColor(.green)
                    }
                }
                .padding(.bottom, 10)
                
                // --- Like/Dislike Buttons ---
                HStack(spacing: 60) {
                    Button(action: {
                        rundjService.sendFeedback(accessToken: token, songId: spotifyManager.currentId, feedback: "LIKE")
                    }) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        rundjService.sendFeedback(accessToken: token, songId: spotifyManager.currentId, feedback: "DISLIKE")
                    }) {
                        Image(systemName: "hand.thumbsdown.fill")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
            
            if !isRunning {
                Button("Start Run") {
                    runManager.requestPermissionsAndStart()
                    isRunning = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Button("Stop Run") {
                    runManager.stop()
                    isRunning = false
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                HStack {
                    VStack {
                        Text("Distance")
                            .padding()
                        Text(runningStatsManager.formatDistance(runningStatsManager.totalDistance))
                    }
                    .frame(maxWidth: .infinity)
                    
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(.gray)
                    
                    VStack {
                        Text("Pace")
                            .padding()
                        Text(runningStatsManager.formatPace(runningStatsManager.currentPace))
                    }
                    .frame(maxWidth: .infinity)
                    
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(.gray)
                    
                    VStack {
                        Text("Time")
                            .padding()
                        Text(runningStatsManager.formatTimeInterval(runningStatsManager.totalElapsedTime))
                    }
                    .frame(maxWidth: .infinity)
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
        .sheet(isPresented: $showingSettingsModal) {
            SettingsView(
                isPresented: $showingSettingsModal,
                onSave: { _ in
                    refreshSongsBasedOnSettings()
                }
            )
        }
        .onChange(of: settingsManager.musicSources) { _, newSources in
            // React to changes in musicSources from SettingsManager, e.g., after modal closes.
            print("Music sources changed in SettingsManager, new sources: \(newSources)")
            refreshSongsBasedOnSettings()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("RunDJ")
                    .font(.title)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        showingSettingsModal = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        showingHelp = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
        }
    }
    
    func initiateSession() {
        // TODO: register user
        spotifyManager.initiateSession {
            refreshSongsBasedOnSettings()
            rundjService.createPlaylist(accessToken: token, bpm: bpm, sources: settingsManager.musicSources, completion: { playlistIdOptional in
                if let playlistId = playlistIdOptional {
                    print("Playlist created with ID: \(playlistId) using sources: \(settingsManager.musicSources)")
                } else {
                    print("Failed to create playlist. Sources: \(settingsManager.musicSources)")
                }
            })
        }
    }
    
    func refreshSongsBasedOnSettings() {
        guard spotifyManager.connectionState == .connected else {
            print("Spotify not connected. Cannot refresh songs.")
            return
        }
        print("Refreshing songs with BPM \(bpm) from sources: \(settingsManager.musicSources)")
        rundjService.getSongsByBPM(accessToken: token, bpm: bpm, sources: settingsManager.musicSources) { fetchedSongs in
            if fetchedSongs.isEmpty {
                print("Failed to get songs or no songs found for current settings.")
            } else {
                print("Successfully fetched \(fetchedSongs.count) songs. Queuing them now.")
                spotifyManager.queue(songs: fetchedSongs)
            }
        }
    }
    
    private var token: String {
        return spotifyManager.getAccessToken() ?? ""
    }
    
    private var connectionStateText: String {
        switch spotifyManager.connectionState {
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    private var buttonText: String {
        switch spotifyManager.connectionState {
        case .connected:
            return "Connected"
        case .disconnected, .error:
            return "Connect to Spotify"
        }
    }
    
    private var buttonColor: Color {
        switch spotifyManager.connectionState {
        case .connected:
            return .gray
        case .disconnected, .error:
            return .green
        }
    }
}

#Preview {
    RunningView(bpm: 160)
        .environmentObject(SettingsManager.shared) // Add for preview
}
