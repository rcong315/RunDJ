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
    @StateObject private var runManager = RunManager.shared
    @StateObject private var runningStatsManager = RunningStatsManager.shared
    @EnvironmentObject var settingsManager: SettingsManager
    
    @State private var showSpotifyError = false
    @State private var errorMessage = ""
    @State private var showingHelp = false
    @State private var isThumbsUpSelected = false
    @State private var isThumbsDownSelected = false
    @State private var isRunning = false
    @State private var showingSettingsModal = false
    
    var bpm: Double
    
    var body: some View {
        VStack {
            if connectionStateText != "Connected" {
                Button(action: {
                    switch spotifyManager.connectionState {
                    case .disconnected:
                        spotifyManager.initiateSession()
                    case .error:
                        spotifyManager.initiateSession()
                    default:
                        break
                    }
                }) {
                    Text("Connect to Spotify")
                        .padding()
                        .background(.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            Text("Spotify Status: \(connectionStateText)")
                .font(.headline)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
            
            Text("Playing: \(spotifyManager.currentlyPlaying)")
            Text("By: \(spotifyManager.currentArtist)")
            Text("BPM: \(String(format: "%.3f", spotifyManager.currentBPM))")
            
            VStack(spacing: 0) {
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
                    
                    Button(action: {
                        spotifyManager.skipToNext()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                }
                .padding(.bottom, 30)
                
                HStack(spacing: 30) {
                    Button(action: {
                        // Send like feedback and make button unclickable
                        isThumbsUpSelected = true
                        isThumbsDownSelected = false // Reset the other button if it was selected
                        rundjService.sendFeedback(accessToken: token, songId: spotifyManager.currentId, feedback: "LIKE") { success in
                            if !success {
                                // Reset on error
                                isThumbsUpSelected = false
                                errorMessage = "Failed to send like feedback"
                                showSpotifyError = true
                            }
                        }
                    }) {
                        Image(systemName: isThumbsUpSelected ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.title)
                            .foregroundColor(.blue)
                            .padding(10)
                    }
                    .disabled(isThumbsUpSelected)
                    
                    Button(action: {
                        isThumbsDownSelected = true
                        isThumbsUpSelected = false
                        spotifyManager.skipToNext()
                        rundjService.sendFeedback(accessToken: token, songId: spotifyManager.currentId, feedback: "DISLIKE") { success in
                            if !success {
                                isThumbsDownSelected = false
                                errorMessage = "Failed to send dislike feedback"
                                showSpotifyError = true
                            }
                        }
                    }) {
                        Image(systemName: isThumbsDownSelected ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                            .font(.title)
                            .foregroundColor(.blue)
                            .padding(10)
                    }
                    .disabled(isThumbsDownSelected)
                }
            }
            .padding()
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
            
            if !isRunning {
                Button("Start Run") {
                    spotifyManager.play(uri: "spotify:track:2HHtWyy5CgaQbC7XSoOb0e")
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
            }
            
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
            .frame(maxHeight: 100)
        }
        .onChange(of: spotifyManager.connectionState) { _, newState in
            switch newState {
            case .error(let message):
                errorMessage = message
                showSpotifyError = true
            case .connected:
                rundjService.register(accessToken: token, completion: { success in
                    if success {
                        print("Successfully registered user")
                    } else {
                        print("Failed to register user")
                    }
                })
                refreshSongsBasedOnSettings()
                rundjService.createPlaylist(accessToken: token, bpm: bpm, sources: settingsManager.musicSources, completion: { playlistIdOptional in
                    if let playlistId = playlistIdOptional {
                        print("Playlist created with ID: \(playlistId) using sources: \(settingsManager.musicSources)")
                    } else {
                        print("Failed to create playlist. Sources: \(settingsManager.musicSources)")
                    }
                })
            default:
                break
            }
        }
        .onAppear() {
            print("On appear")
            if (connectionStateText == "Connected") {
                refreshSongsBasedOnSettings()
            }
        }
        .onChange(of: spotifyManager.currentId) { _, _ in
            isThumbsUpSelected = false
            isThumbsDownSelected = false
        }
        .onChange(of: settingsManager.musicSources) { _, newSources in
            print("Music sources changed in SettingsManager, new sources: \(newSources)")
            refreshSongsBasedOnSettings()
        }
        .alert(isPresented: $showSpotifyError) {
            return Alert(
                title: Text("Spotify Connection Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingHelp) {
            HelpView(context: .runningView)
        }
        .sheet(isPresented: $showingSettingsModal) {
            SettingsView(
                isPresented: $showingSettingsModal,
                onSave: { _ in
                    refreshSongsBasedOnSettings()
                }
            )
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(Int(round(bpm))) BPM")
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
}

#Preview {
    RunningView(bpm: 160)
        .environmentObject(SettingsManager.shared) // Add for preview
}
