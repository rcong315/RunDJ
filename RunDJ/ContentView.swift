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
    @StateObject private var spotifyManager = SpotifyManager.shared  // Use the shared instance
    
    @State private var showSpotifyError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Playing: \(spotifyManager.currentTrack ?? "None")")
                .padding()
            
            Text("Steps Per Minute: \(pedometerManager.stepsPerMinute)")
                .padding()
            
            Button(action: {
                spotifyManager.playPresetPlaylist(stepsPerMinute: pedometerManager.stepsPerMinute)
            }) {
                Text("Start")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
//            Button(action: {
//                spotifyManager.skipToNext()
//            }) {
//                Text("Next Song")
//                    .padding()
//                    .background(Color.orange)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }
        }
        .padding()
        .onAppear {
            spotifyManager.connect()
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
        .alert("Spotify Connection Error",
               isPresented: $showSpotifyError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    ContentView()
}
