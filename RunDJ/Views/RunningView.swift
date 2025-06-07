//
//  RunningView.swift
//  RunDJ
//
//  Created by Richard Cong on 2/8/25.
//

import SwiftUI
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
    @State private var confirmationColor = Color.rundjMusicGreen
    @State private var isPlaylistButtonDisabled = true
    
    var bpm: Double
    
    var body: some View {
        ZStack {
            Color.rundjBackground
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Spotify Connection Section
                SpotifyConnectionPromptView(spotifyManager: spotifyManager)
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                
                // Connection Status (Compact)
                HStack {
                    Circle()
                        .fill(spotifyManager.connectionState == .connected ? Color.rundjMusicGreen : Color.rundjError)
                        .frame(width: 8, height: 8)
                    Text(connectionStateText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.rundjTextSecondary)
                }
                .padding(.horizontal)
                
                // Now Playing Section
                NowPlayingCompactView(spotifyManager: spotifyManager)
                    .padding(.horizontal)
                
                // Playback Controls
                PlaybackControlsCompactView(spotifyManager: spotifyManager, onSpotifyError: handleSpotifyError)
                    .padding(.vertical, 8)
                
                // Action Buttons
                ActionButtonsCompactView(
                    spotifyManager: spotifyManager,
                    rundjService: rundjService,
                    settingsManager: settingsManager,
                    token: token,
                    bpm: bpm,
                    isPlaylistButtonDisabled: $isPlaylistButtonDisabled,
                    isThumbsUpSelected: $isThumbsUpSelected,
                    isThumbsDownSelected: $isThumbsDownSelected,
                    showConfirmationMessage: showConfirmationMessage,
                    onSpotifyError: handleSpotifyError
                )
                .padding(.horizontal)
                
                RundjDivider()
                    .padding(.vertical, 4)
                
                // Run Control
                RunControlCompactView(isRunning: $isRunning, runManager: runManager)
                    .padding(.horizontal)
                
                // Run Stats
                RunStatsCompactView(pedometerManager: pedometerManager, runningStatsManager: runningStatsManager)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
            .padding(.top, 8)
            
            // Confirmation Overlay
            if showConfirmation {
                VStack {
                    HStack {
                        Text(confirmationMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(confirmationColor)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.top, 50)
                    Spacer()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
                .zIndex(1)
                .animation(.easeInOut(duration: 0.3), value: showConfirmation)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: spotifyManager.connectionState) { _, newState in
            handleConnectionStateChange(newState)
        }
        .onAppear {
            setupOnAppear()
        }
        .onChange(of: spotifyManager.currentId) { _, _ in
            isThumbsUpSelected = false
            isThumbsDownSelected = false
        }
        .onChange(of: settingsManager.musicSources) { _, _ in
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
                onSave: { _ in refreshSongsBasedOnSettings() }
            )
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text("\(Int(round(bpm)))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.rundjMusicGreen)
                    Text("BPM")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.rundjTextSecondary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: { showingSettingsModal = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.rundjAccent)
                    }
                    Button(action: { showingHelp = true }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.rundjAccent)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func handleConnectionStateChange(_ newState: SpotifyManager.ConnectionState) {
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
                } else {
                    print("Failed to register user")
                }
            }
            refreshSongsBasedOnSettings()
        case .disconnected:
            isPlaylistButtonDisabled = true
        }
    }
    
    private func setupOnAppear() {
        print("RunningView onAppear. Current BPM: \(bpm)")
        if spotifyManager.connectionState == .connected {
            refreshSongsBasedOnSettings()
            isPlaylistButtonDisabled = false
        } else {
            isPlaylistButtonDisabled = true
        }
    }
    
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
        showConfirmationMessage("Flushing queue, please wait...", color: .rundjAccent)
        
        rundjService.getSongsByBPM(accessToken: token, bpm: bpm, sources: settingsManager.musicSources) { fetchedSongs in
            DispatchQueue.main.async {
                if fetchedSongs.isEmpty {
                    self.showConfirmationMessage("No songs found", color: .rundjWarning)
                } else {
                    Task {
                        await self.spotifyManager.flushQueue()
                        await self.spotifyManager.queueSongs(fetchedSongs)
                        self.showConfirmationMessage("\(fetchedSongs.count) songs queued!", color: .rundjMusicGreen)
                    }
                }
            }
        }
    }
    
    func showConfirmationMessage(_ message: String, color: Color = .rundjMusicGreen) {
        confirmationMessage = message
        confirmationColor = color
        withAnimation {
            showConfirmation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
        case .error: return "Error"
        }
    }
}

// MARK: - Compact View Components

struct SpotifyConnectionPromptView: View {
    @ObservedObject var spotifyManager: SpotifyManager
    
    private var connected: Bool {
        spotifyManager.connectionState == .connected
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.house.fill")
                .font(.system(size: 32))
                .foregroundColor(.rundjMusicGreen)
            
            Text("Connect Spotify to start")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.rundjTextPrimary)
            
            Button(action: {
                switch spotifyManager.connectionState {
                case .disconnected, .error:
                    spotifyManager.initiateSession()
                default:
                    break
                }
            }) {
                Text("Connect Spotify")
            }
            .buttonStyle(RundjPrimaryButtonStyle(isDisabled: connected, isMusic: true))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.rundjCardBackground)
        .cornerRadius(12)
    }
}

struct NowPlayingCompactView: View {
    @ObservedObject var spotifyManager: SpotifyManager
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "music.note")
                    .font(.system(size: 14))
                    .foregroundColor(.rundjMusicGreen)
                Text("Now Playing")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.rundjTextSecondary)
            }
            
            if !spotifyManager.hasQueuedSongs && spotifyManager.connectionState == .connected {
                Text("No songs queued")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.rundjWarning)
                
                Text("Check settings or change BPM")
                    .font(.system(size: 14))
                    .foregroundColor(.rundjTextSecondary)
            } else {
                Text(spotifyManager.currentlyPlaying.isEmpty ? "Nothing playing" : spotifyManager.currentlyPlaying)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.rundjTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(spotifyManager.currentArtist.isEmpty ? "—" : spotifyManager.currentArtist)
                    .font(.system(size: 14))
                    .foregroundColor(.rundjTextSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                if spotifyManager.currentBPM > 0 {
                    Text("\(Int(spotifyManager.currentBPM)) BPM")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.rundjMusicGreen)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.rundjCardBackground)
        .cornerRadius(12)
    }
}

struct PlaybackControlsCompactView: View {
    @ObservedObject var spotifyManager: SpotifyManager
    var onSpotifyError: (Error, String) -> Void
    
    private var isDisabled: Bool {
        spotifyManager.connectionState != .connected || !spotifyManager.hasQueuedSongs
    }
    
    var body: some View {
        HStack(spacing: 32) {
            Button(action: {
                Task {
                    do { try await spotifyManager.rewindTrack() }
                    catch { onSpotifyError(error, "Failed to rewind.") }
                }
            }) {
                Image(systemName: "backward.fill")
            }
            .buttonStyle(RundjIconButtonStyle(size: 40, color: .rundjMusicGreen, isDisabled: isDisabled))
            
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
            }
            .buttonStyle(RundjIconButtonStyle(size: 56, color: .rundjMusicGreen, isDisabled: isDisabled))
            
            Button(action: {
                Task {
                    do { try await spotifyManager.skipToNextTrack() }
                    catch { onSpotifyError(error, "Failed to skip.") }
                }
            }) {
                Image(systemName: "forward.fill")
            }
            .buttonStyle(RundjIconButtonStyle(size: 40, color: .rundjMusicGreen, isDisabled: isDisabled))
        }
        .disabled(isDisabled)
    }
}

struct ActionButtonsCompactView: View {
    @ObservedObject var spotifyManager: SpotifyManager
    @ObservedObject var rundjService: RunDJService
    @ObservedObject var settingsManager: SettingsManager
    
    let token: String
    let bpm: Double
    
    @Binding var isPlaylistButtonDisabled: Bool
    @Binding var isThumbsUpSelected: Bool
    @Binding var isThumbsDownSelected: Bool
    
    var showConfirmationMessage: (String, Color) -> Void
    var onSpotifyError: (Error, String) -> Void
    
    private var isDisabled: Bool {
        spotifyManager.connectionState != .connected || !spotifyManager.hasQueuedSongs
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                isPlaylistButtonDisabled = true
                showConfirmationMessage("Creating playlist...", .rundjAccent)
                rundjService.createPlaylist(accessToken: token, bpm: bpm, sources: settingsManager.musicSources) { playlistIdOptional in
                    DispatchQueue.main.async {
                        if playlistIdOptional != nil {
                            showConfirmationMessage("Playlist saved!", .rundjMusicGreen)
                        } else {
                            showConfirmationMessage("Failed to save", .rundjError)
                            isPlaylistButtonDisabled = spotifyManager.connectionState != .connected
                        }
                    }
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 14))
                    Text("Save Playlist")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .buttonStyle(RundjButtonStyle(isDisabled: isPlaylistButtonDisabled || spotifyManager.connectionState != .connected))
            
            Spacer()
            
            Button(action: {
                guard !spotifyManager.currentId.isEmpty else { return }
                isThumbsUpSelected = true
                isThumbsDownSelected = false
                showConfirmationMessage("Liked!", .rundjMusicGreen)
                rundjService.sendFeedback(accessToken: token, songId: spotifyManager.currentId, feedback: "LIKE") { success in
                    if !success {
                        DispatchQueue.main.async {
                            isThumbsUpSelected = false
                            showConfirmationMessage("Failed to like", .rundjError)
                        }
                    }
                }
            }) {
                Image(systemName: isThumbsUpSelected ? "hand.thumbsup.fill" : "hand.thumbsup")
            }
            .buttonStyle(RundjIconButtonStyle(
                size: 36,
                color: .rundjMusicGreen,
                isDisabled: spotifyManager.currentId.isEmpty || isThumbsUpSelected || isDisabled))
            
            Button(action: {
                guard !spotifyManager.currentId.isEmpty else { return }
                isThumbsDownSelected = true
                isThumbsUpSelected = false
                showConfirmationMessage("Skipping...", .rundjWarning)
                Task {
                    async let skipTask: () = spotifyManager.skipToNextTrack()
                    rundjService.sendFeedback(accessToken: token, songId: spotifyManager.currentId, feedback: "DISLIKE") { _ in }
                    do { try await skipTask } catch {
                        DispatchQueue.main.async { onSpotifyError(error, "Failed to skip.") }
                    }
                }
            }) {
                Image(systemName: isThumbsDownSelected ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            .buttonStyle(RundjIconButtonStyle(
                size: 36,
                color: .rundjError,
                isDisabled: spotifyManager.currentId.isEmpty || isThumbsDownSelected || isDisabled))
        }
    }
}

struct RunControlCompactView: View {
    @Binding var isRunning: Bool
    @ObservedObject var runManager: RunManager
    
    var body: some View {
        Button(action: {
            if !isRunning {
                runManager.requestPermissionsAndStart()
                isRunning = true
            } else {
                runManager.stop()
                isRunning = false
            }
        }) {
            HStack {
                Image(systemName: isRunning ? "stop.fill" : "figure.run")
                    .font(.system(size: 16))
                Text(isRunning ? "Stop Run" : "Start Run")
                    .font(.system(size: 16, weight: .semibold))
            }
        }
        .buttonStyle(RundjPrimaryButtonStyle(isDisabled: false))
        .padding(.vertical, 8)
    }
}

struct RunStatsCompactView: View {
    @ObservedObject var pedometerManager: PedometerManager
    @ObservedObject var runningStatsManager: RunningStatsManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Current SPM
            VStack(spacing: 4) {
                Text("Current Pace")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.rundjTextSecondary)
                HStack(spacing: 4) {
                    Text("\(Int(pedometerManager.stepsPerMinute))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.rundjMusicGreen)
                    Text("SPM")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.rundjTextSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.rundjCardBackground)
            .cornerRadius(12)
            
            // Stats Grid
            HStack(spacing: 8) {
                RundjStatCard(
                    title: "Distance",
                    value: runningStatsManager.formatDistance(runningStatsManager.totalDistance),
                    icon: "location.fill"
                )
                
                RundjStatCard(
                    title: "Pace",
                    value: runningStatsManager.formatPace(runningStatsManager.currentPace),
                    icon: "speedometer"
                )
                
                RundjStatCard(
                    title: "Time",
                    value: runningStatsManager.formatTimeInterval(runningStatsManager.totalElapsedTime),
                    icon: "timer"
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        RunningView(bpm: 160)
            .environmentObject(SettingsManager.shared)
    }
}
