//
//  ContentView.swift
//  RunDJ
//
//  Created by Richard Cong on 2/8/25.
//

import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @StateObject private var pedometerManager = PedometerManager()
    @StateObject private var spotifyManager = SpotifyManager.shared
    @StateObject private var rundjService = RunDJService()
    
    @State private var showSpotifyError = false
    @State private var errorMessage = ""
    @State private var showingHelp = false
    @State private var showCopiedNotification = false
    
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
            
            Text("Status: \(connectionStateText)")
                .padding()
            
            Text("Playing: \(spotifyManager.currentlyPlaying ?? "None")")
                .padding()
            
            Text("Steps Per Minute: \(pedometerManager.stepsPerMinute)")
                .padding()
            
            Button(action: {
                switch spotifyManager.connectionState {
                case .disconnected:
                    spotifyManager.initiateSession()
                case .connected:
                    rundjService.getSongsByBPM(accessToken: spotifyManager.getAccessToken()!, stepsPerMinute: pedometerManager.stepsPerMinute) { songs in
                        if songs.isEmpty {
                            print("Error getting songs")
                        } else {
                            spotifyManager.queue(songs: songs)
                        }
                    }
                case .error:
                    spotifyManager.initiateSession()
                }
            }) {
                Text(buttonText)
                    .padding()
                    .background(buttonColor)
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
    
    private var buttonColor: Color {
        switch spotifyManager.connectionState {
        case .connected:
            return .blue
        case .disconnected, .error:
            return .green
        }
    }
}

#Preview {
    ContentView()
}
