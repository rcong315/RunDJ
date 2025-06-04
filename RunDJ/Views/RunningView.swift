//
//  RunningView.swift
//  RunDJ
//
//  Created by Richard Cong on 2/8/25.
//

import SwiftUI
//import SwiftData
import Sentry

struct RunningView: View {
    @StateObject private var rundjService = RunDJService.shared
    @StateObject private var spotifyManager = SpotifyManager.shared
    @StateObject private var pedometerManager = PedometerManager.shared
    @StateObject private var runManager = RunManager.shared
    @StateObject private var runningStatsManager = RunningStatsManager.shared
    @EnvironmentObject var settingsManager: SettingsManager
    
    @State private var showSpotifyErrorAlert = false
    @State private var spotifyErrorMessage = ""
    @State private var showingHelp = false
    @State private var isThumbsUpSelected = false
    @State private var isThumbsDownSelected = false
    @State private var isRunning = false
    @State private var showingSettingsModal = false
    @State private var showConfirmation = false
    @State private var confirmationMessage = ""
    @State private var confirmationColor = Color.green
    @State private var isPlaylistButtonDisabled = true // Start disabled until Spotify connects
    
    var bpm: Double
    
    var body: some View {
        ZStack {
            VStack(spacing: 15) {
                // Spotify Connection
                SpotifyConnectionPromptView(spotifyManager: spotifyManager)
                    .opacity(spotifyManager.connectionState != .connected ? 1.0 : 0.0)
                // Only allow interactions with the prompt view if it's visible (i.e., not connected)
                    .allowsHitTesting(spotifyManager.connectionState != .connected)
                
                Text("Spotify Status: \(connectionStateText)")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                DividerView()
                
                NowPlayingView(spotifyManager: spotifyManager)
                
                // Playback Controls Section
                VStack(spacing: 0) {
                    PlaybackControlsView(spotifyManager: spotifyManager, onSpotifyError: handleSpotifyError)
                    ActionButtonsView(
                        spotifyManager: spotifyManager,
                        rundjService: rundjService,
                        settingsManager: settingsManager, // Passed as ObservedObject
                        token: token,
                        bpm: bpm,
                        isPlaylistButtonDisabled: $isPlaylistButtonDisabled,
                        isThumbsUpSelected: $isThumbsUpSelected,
                        isThumbsDownSelected: $isThumbsDownSelected,
                        showConfirmationMessage: showConfirmationMessage,
                        onSpotifyError: handleSpotifyError
                    )
                }
                .padding(.bottom) // Padding for the whole controls section
                
                DividerView()
                
                RunControlView(isRunning: $isRunning, runManager: runManager)
                
                RunStatsHorizontalView(pedometerManager: pedometerManager, runningStatsManager: runningStatsManager)
                
                Spacer() // Pushes content to the top
            }
            .padding(.top) // Add some padding at the top of the VStack
            
            // Confirmation Overlay
            if showConfirmation {
                VStack {
                    HStack {
                        Text(confirmationMessage)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(confirmationColor)
                            .cornerRadius(8)
                            .shadow(radius: 4)
                    }
                    .padding(.top, 50)
                    Spacer()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity.combined(with: .move(edge: .top)))
                )
                .zIndex(1)
                .animation(.easeInOut(duration: 0.3), value: showConfirmation)
            }
        }
        .onChange(of: spotifyManager.connectionState) { _, newState in // For Swift 5.5+
            switch newState {
            case .error(let message):
                spotifyErrorMessage = message
                showSpotifyErrorAlert = true
                isPlaylistButtonDisabled = true
                SentrySDK.capture(message: "Spotify connection error displayed to user") { scope in
                    scope.setContext(value: ["error_message": message], key: "ui_error")
                    scope.setLevel(.warning)
                }
            case .connected:
                isPlaylistButtonDisabled = false
                rundjService.register(accessToken: token) { success in
                    if success {
                        print("Successfully registered user")
                        let breadcrumb = Breadcrumb(level: .info, category: "user")
                        breadcrumb.message = "User registered successfully"
                        SentrySDK.addBreadcrumb(breadcrumb)
                    } else {
                        print("Failed to register user")
                        SentrySDK.capture(message: "Failed to register user") { scope in scope.setLevel(.error) }
                    }
                }
                refreshSongsBasedOnSettings()
            case .disconnected:
                isPlaylistButtonDisabled = true
            }
        }
        .onAppear() {
            print("RunningView onAppear. Current BPM: \(bpm)")
            if spotifyManager.connectionState == .connected {
                refreshSongsBasedOnSettings()
                isPlaylistButtonDisabled = false
            } else {
                isPlaylistButtonDisabled = true
                if spotifyManager.getAccessToken() == nil {
                    // Consider if auto-initiation is desired or should be user-driven
                    // spotifyManager.initiateSession()
                }
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
        .alert("Spotify Error", isPresented: $showSpotifyErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(spotifyErrorMessage)
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
                    .font(.title2)
                    .fontWeight(.bold)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { showingSettingsModal = true }) {
                        Image(systemName: "gearshape.fill")
                            .imageScale(.large)
                    }
                    Button(action: { showingHelp = true }) {
                        Image(systemName: "questionmark.circle.fill")
                            .imageScale(.large)
                    }
                }
                .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func handleSpotifyError(_ error: Error, message: String) {
        print("\(message) Error: \(error.localizedDescription)")
        spotifyErrorMessage = "\(message)\nDetails: \(error.localizedDescription)"
        showSpotifyErrorAlert = true
        SentrySDK.capture(error: error) { scope in
            scope.setContext(value: ["user_action_message": message], key: "spotify_action_error")
        }
    }
    
    func refreshSongsBasedOnSettings() {
        guard spotifyManager.connectionState == .connected else {
            print("Spotify not connected. Cannot refresh songs.")
            return
        }
        print("Refreshing songs with BPM \(bpm) from sources: \(settingsManager.musicSources)")
        showConfirmationMessage("One moment, finding songs...", color: .blue)
        
        rundjService.getSongsByBPM(accessToken: token, bpm: bpm, sources: settingsManager.musicSources) { fetchedSongs in
            DispatchQueue.main.async {
                if fetchedSongs.isEmpty {
                    print("Failed to get songs or no songs found for current settings.")
                    self.showConfirmationMessage("No songs found for \(Int(round(bpm))) BPM.", color: .orange)
                } else {
                    print("Successfully fetched \(fetchedSongs.count) songs. Flushing queue and adding new songs.")
                    Task { // This Task runs on MainActor due to refreshSongsBasedOnSettings' context
                        await self.spotifyManager.flushQueue()
                        await self.spotifyManager.queueSongs(fetchedSongs)
                        self.showConfirmationMessage("\(fetchedSongs.count) songs queued!", color: .green)
                    }
                }
            }
        }
    }
    
    func showConfirmationMessage(_ message: String, color: Color = .green) {
        confirmationMessage = message
        confirmationColor = color
        withAnimation {
            showConfirmation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showConfirmation = false
            }
        }
    }
    
    private var token: String {
        return spotifyManager.getAccessToken() ?? ""
    }
    
    private var connectionStateText: String {
        switch spotifyManager.connectionState {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .error(let message):
            let shortMessage = message.prefix(50) + (message.count > 50 ? "..." : "")
            return "Error: \(shortMessage)"
        }
    }
}

// MARK: - Child View Components

struct SpotifyConnectionPromptView: View {
    @ObservedObject var spotifyManager: SpotifyManager
    
    var body: some View {
        Button(action: {
            switch spotifyManager.connectionState {
            case .disconnected, .error:
                spotifyManager.initiateSession()
            default:
                break
            }
        }) {
            VStack {
                Text("Please connect your Spotify account")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Text("Connect Spotify")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.vertical)
        }
    }
}

struct DividerView: View {
    var body: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(.gray.opacity(0.5))
            .padding(.horizontal, 20)
    }
}

struct NowPlayingView: View {
    @ObservedObject var spotifyManager: SpotifyManager
    
    var body: some View {
        Group {
            Text("Playing: \(spotifyManager.currentlyPlaying.isEmpty ? "N/A" : spotifyManager.currentlyPlaying)")
                .lineLimit(1)
            Text("By: \(spotifyManager.currentArtist.isEmpty ? "N/A" : spotifyManager.currentArtist)")
                .lineLimit(1)
            Text("Track BPM: \(spotifyManager.currentBPM == 0.0 ? "N/A" : String(format: "%.1f", spotifyManager.currentBPM))")
        }
        .font(.headline)
        .padding(.horizontal)
        .frame(minHeight: 30) // Ensure some space for text
    }
}

struct PlaybackControlsView: View {
    @ObservedObject var spotifyManager: SpotifyManager
    var onSpotifyError: (Error, String) -> Void
    
    var body: some View {
        HStack(spacing: 40) {
            Button(action: {
                Task {
                    do { try await spotifyManager.rewindTrack() }
                    catch { onSpotifyError(error, "Failed to rewind.") }
                }
            }) {
                Image(systemName: "backward.fill")
                    .font(.title)
            }
            .disabled(spotifyManager.connectionState != .connected)
            
            Button(action: {
                Task {
                    do {
                        if spotifyManager.isPlaying { try await spotifyManager.pausePlayback() }
                        else { try await spotifyManager.resumePlayback() }
                    } catch {
                        onSpotifyError(error, spotifyManager.isPlaying ? "Failed to pause." : "Failed to resume.")
                    }
                }
            }) {
                Image(systemName: spotifyManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 44))
            }
            .disabled(spotifyManager.connectionState != .connected)
            
            Button(action: {
                Task {
                    do { try await spotifyManager.skipToNextTrack() }
                    catch { onSpotifyError(error, "Failed to skip.") }
                }
            }) {
                Image(systemName: "forward.fill")
                    .font(.title)
            }
            .disabled(spotifyManager.connectionState != .connected)
        }
        .foregroundColor(spotifyManager.connectionState == .connected ? .green : .gray) // Apply to all buttons in HStack
        .padding(.vertical, 20)
    }
}

struct ActionButtonsView: View {
    @ObservedObject var spotifyManager: SpotifyManager
    @ObservedObject var rundjService: RunDJService
    @ObservedObject var settingsManager: SettingsManager // Changed to ObservedObject
    
    let token: String
    let bpm: Double
    
    @Binding var isPlaylistButtonDisabled: Bool
    @Binding var isThumbsUpSelected: Bool
    @Binding var isThumbsDownSelected: Bool
    
    var showConfirmationMessage: (String, Color) -> Void
    var onSpotifyError: (Error, String) -> Void
    
    var body: some View {
        HStack(spacing: 30) {
            Button(action: {
                isPlaylistButtonDisabled = true
                showConfirmationMessage("Creating playlist...", .blue)
                rundjService.createPlaylist(accessToken: token, bpm: bpm, sources: settingsManager.musicSources) { playlistIdOptional in
                    DispatchQueue.main.async {
                        if let playlistId = playlistIdOptional {
                            print("Playlist created with ID: \(playlistId)")
                            showConfirmationMessage("Playlist saved!", .green)
                        } else {
                            showConfirmationMessage("Failed to save playlist", .red)
                            isPlaylistButtonDisabled = spotifyManager.connectionState != .connected
                        }
                    }
                }
            }) {
                Text("Save Playlist")
                    .foregroundColor(isPlaylistButtonDisabled || spotifyManager.connectionState != .connected ? .gray : .blue)
            }
            .disabled(isPlaylistButtonDisabled || spotifyManager.connectionState != .connected)
            
            Button(action: {
                guard !spotifyManager.currentId.isEmpty else { return }
                isThumbsUpSelected = true
                isThumbsDownSelected = false
                showConfirmationMessage("Song liked!", .blue)
                rundjService.sendFeedback(accessToken: token, songId: spotifyManager.currentId, feedback: "LIKE") { success in
                    DispatchQueue.main.async {
                        if !success {
                            isThumbsUpSelected = false
                            showConfirmationMessage("Failed to like song", .red)
                            SentrySDK.capture(message: "Failed to send like feedback") { scope in
                                scope.setContext(value: ["song_id": spotifyManager.currentId], key: "feedback_like_fail")
                                scope.setLevel(.warning)
                            }
                        }
                    }
                }
            }) {
                Image(systemName: isThumbsUpSelected ? "hand.thumbsup.fill" : "hand.thumbsup")
            }
            .disabled(spotifyManager.currentId.isEmpty || isThumbsUpSelected || spotifyManager.connectionState != .connected)
            
            Button(action: {
                guard !spotifyManager.currentId.isEmpty else { return }
                isThumbsDownSelected = true
                isThumbsUpSelected = false
                showConfirmationMessage("Song disliked, skipping...", .orange)
                Task {
                    async let skipTask: () = spotifyManager.skipToNextTrack()
                    rundjService.sendFeedback(accessToken: token, songId: spotifyManager.currentId, feedback: "DISLIKE") { success in
                        DispatchQueue.main.async {
                            if !success {
                                showConfirmationMessage("Failed to send dislike feedback", .red)
                                SentrySDK.capture(message: "Failed to send dislike feedback") { scope in
                                    scope.setContext(value: ["song_id": spotifyManager.currentId], key: "feedback_dislike_fail")
                                    scope.setLevel(.warning)
                                }
                            }
                        }
                    }
                    do { try await skipTask } catch {
                        DispatchQueue.main.async { onSpotifyError(error, "Failed to skip after dislike.") }
                    }
                }
            }) {
                Image(systemName: isThumbsDownSelected ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            .disabled(spotifyManager.currentId.isEmpty || isThumbsDownSelected || spotifyManager.connectionState != .connected)
        }
        .font(.title) // Apply font to all images in HStack
        .foregroundColor(spotifyManager.currentId.isEmpty || spotifyManager.connectionState != .connected ? .gray : .blue) // Default color for icons
        .padding(.bottom) // Add some padding below these action buttons
    }
}

struct RunControlView: View {
    @Binding var isRunning: Bool
    @ObservedObject var runManager: RunManager
    
    var body: some View {
        if !isRunning {
            Button("Start Run") {
                runManager.requestPermissionsAndStart()
                isRunning = true
            }
            .buttonStyle(PrimaryActionButtonStyle(backgroundColor: .blue))
        } else {
            Button("Stop Run") {
                runManager.stop()
                isRunning = false
            }
            .buttonStyle(PrimaryActionButtonStyle(backgroundColor: .red))
        }
    }
}

struct RunStatsHorizontalView: View {
    @ObservedObject var pedometerManager: PedometerManager
    @ObservedObject var runningStatsManager: RunningStatsManager
    
    var body: some View {
        StatView(title: "Current Steps Per Minute", value: pedometerManager.stepsPerMinute.formatted(.number.precision(.fractionLength(1))))
        HStack {
            StatView(title: "Distance", value: runningStatsManager.formatDistance(runningStatsManager.totalDistance))
            Divider() // Uses the standard SwiftUI Divider
            StatView(title: "Pace", value: runningStatsManager.formatPace(runningStatsManager.currentPace))
            Divider()
            StatView(title: "Time", value: runningStatsManager.formatTimeInterval(runningStatsManager.totalElapsedTime))
        }
        .frame(maxHeight: 100)
        .padding(.vertical)
    }
}

// MARK: - Helper Structs (Styles, Small Views)

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PrimaryActionButtonStyle: ButtonStyle {
    let backgroundColor: Color
    
    // Use explicit ButtonStyleConfiguration for the parameter type
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .padding() // Padding for the content (e.g., Text)
            .frame(maxWidth: .infinity) // Make the button's content area stretch
            .background(backgroundColor) // Apply background to the padded content area
            .foregroundColor(.white) // Text color on the background
        // The .padding(.horizontal) that was here previously was applied *after* the background
        // and corner radius. If you intended to make the backgrounded area wider,
        // that padding should be applied *before* .background().
        // If it was for spacing around the button, apply it to the Button instance itself.
        // For now, I'm assuming the single .padding() above is for content padding.
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(), value: configuration.isPressed) // Animate scale effect based on press state
    }
}

#Preview {
    RunningView(bpm: 160)
        .environmentObject(SettingsManager.shared) // Add for preview
}
