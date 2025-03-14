//
//  ContentView.swift
//  RunDJ
//
//  Created by Richard Cong on 2/8/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var pedometerManager = PedometerManager()
    @StateObject private var spotifyManager = SpotifyManager2.shared
    @StateObject private var playlistService = RunDJService()
    
    @State private var showSpotifyError = false
    @State private var errorMessage = ""
    @State private var showingGuide = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: {
                    showingGuide = true
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .padding()
            }
            
            Text("Status: \(connectionStateText)")
                .padding()
            
//            Text("Playing: \(spotifyManager.currentlyPlaying ?? "None")")
//                .padding()
            
            Text("Steps Per Minute: \(pedometerManager.stepsPerMinute)")
                .padding()
            
            Button(action: {
                switch spotifyManager.connectionState {
                case .disconnected:
                    spotifyManager.initiateSession()
                case .connected:
                    playlistService.getPresetPlaylist(stepsPerMinute: pedometerManager.stepsPerMinute) { uri in
                        if let uri = uri {
                            print(uri)
                            spotifyManager.play(uri: uri)
                        } else {
                            print("Failed to get playlist URI")
                        }
                    }
                    
                case .error:
                    spotifyManager.initiateSession()
                }
            }) {
                Text(buttonText)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Button(action: {
//                spotifyManager.playPause()
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
            
#if DEBUG
            // Debug-only controls
            Divider()
                .padding(.vertical)
            
            Button(action: {
                // Show confirmation dialog
                errorMessage = "This will clear all Spotify authentication data. You'll need to log in again."
                showSpotifyError = true
                
                // Use this approach if you want to directly clear without confirmation
                // spotifyManager.clearSpotifyKeychain()
            }) {
                Text("Clear Spotify Keychain (Debug)")
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .font(.callout)
            }
#endif
            
        }
        .padding()
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
            if errorMessage.contains("This will clear all Spotify authentication") {
                // It's a keychain clear confirmation
                return Alert(
                    title: Text("Clear Keychain?"),
                    message: Text(errorMessage),
                    primaryButton: .destructive(Text("Clear")) {
//                        spotifyManager.clearSpotifyKeychain()
                    },
                    secondaryButton: .cancel()
                )
            } else {
                // It's a regular error message
                return Alert(
                    title: Text("Spotify Connection Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .sheet(isPresented: $showingGuide) {
            GuideView()
        }
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
            return "Play Music"
        case .disconnected, .error:
            return "Connect to Spotify"
        }
    }
    
}

#Preview {
    ContentView()
}
