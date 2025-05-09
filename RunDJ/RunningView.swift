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
    
    @State private var songs = []
    
    var bpm: Double
    var sources: [String]
    
    var body: some View {
        NavigationView() {
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
                
                Spacer()
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                Spacer()
                
                Text("Set BPM: \(bpm)")
                    .font(.title3)
                
                Text("Playing: \(spotifyManager.currentlyPlaying ?? "") \n BPM: \(spotifyManager.currentBPM ?? 0.0)")
                    .font(.title3)
                    .padding()
                
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
                .padding()
                
                Spacer()
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                Spacer()
                
                HStack {
                    VStack {
                        Text("Distance")
                            .padding()
                        Text("12mi")
                    }
                    .frame(maxWidth: .infinity)
                    
                    
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(.gray)
                    
                    VStack {
                        Text("Steps Per Minute")
                            .padding()
                        Text("\(pedometerManager.stepsPerMinute)")
                    }
                    .frame(maxWidth: .infinity)
                    
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(.gray)
                    
                    VStack {
                        Text("Time")
                            .padding()
                        Text("12:34")
                    }
                    .frame(maxWidth: .infinity)
                }
                
                //                VStack() {
                //                    Text("Access Token")
                //                        .font(.system(size: 30))
                //                    Text(spotifyManager.getAccessToken()?.replacingOccurrences(of: "-", with: "\u{2011}") ?? "")
                //                        .font(.system(size: 10))
                //                        .contextMenu {
                //                            Button(action: {
                //                                UIPasteboard.general.string = String(pedometerManager.stepsPerMinute)
                //                            }) {
                //                                Label("Copy", systemImage: "doc.on.doc")
                //                            }
                //                        }
                //                        .onTapGesture {
                //                            UIPasteboard.general.string = String(pedometerManager.stepsPerMinute)
                //                            let generator = UINotificationFeedbackGenerator()
                //                            generator.notificationOccurred(.success)
                //                            showCopiedNotification = true
                //                        }
                //
                //                    Text("Tap to copy")
                //                        .font(.caption)
                //                        .foregroundColor(.secondary)
                //                }
                //                .padding()
                //                .overlay(
                //                    Group {
                //                        if showCopiedNotification {
                //                            VStack {
                //                                Text("Copied to clipboard")
                //                                    .padding()
                //                                    .background(Color.blue.opacity(0.7))
                //                                    .foregroundColor(.white)
                //                                    .cornerRadius(10)
                //                                    .shadow(radius: 3)
                //                            }
                //                            .transition(.move(edge: .bottom).combined(with: .opacity))
                //                            .onAppear {
                //                                withAnimation(.easeOut(duration: 0.5).delay(1.5)) {
                //                                    showCopiedNotification = false
                //                                }
                //                            }
                //                        }
                //                    }
                //                )
            }
            //            .onAppear {
            //                token = spotifyManager.getAccessToken() ?? ""
            //                rundjService.getSongsByBPM(accessToken: token, bpm: bpm, sources: sources) { fetchedSongs in
            //                    if !songs.isEmpty {
            //                        spotifyManager.queue(songs: fetchedSongs)
            //                    }
            //                }
            //            }
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
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("RunDJ")
                    .font(.title)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingHelp = true
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding()
            }
        }
    }
    
    func initiateSession() {
        // TODO: register user
        spotifyManager.initiateSession {
            rundjService.getSongsByBPM(accessToken: token, bpm: bpm, sources: sources, completion: { fetchedSongs in
                print("Getting songs with BPM \(bpm) from \(sources)")
                if fetchedSongs.isEmpty {
                    print("Failed to get songs")
                } else {
                    spotifyManager.queue(songs: fetchedSongs)
                }
            })
            rundjService.createPlaylist(accessToken: token, bpm: bpm, sources: sources, completion: { playlistId in
                print(playlistId)
            })
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
    RunningView(bpm: 160, sources: [])
}
