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
    @StateObject private var spotifyManager = SpotifyManager.shared
    @StateObject private var playlistService = PlaylistService()
    
    @State private var showSpotifyError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Status: \(connectionStateText)")
                .padding()
            
            Text("Playing: \(spotifyManager.currentTrack ?? "None")")
                .padding()
            
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
                spotifyManager.skipToNext()
            }) {
                Text("Next Song")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
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
        .alert("Spotify Connection Error",
               isPresented: $showSpotifyError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
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
