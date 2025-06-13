//
//  RunningView.swift
//  RunDJ
//
//  Created by Richard Cong on 2/8/25.
//

import SwiftUI
import Sentry
import ActivityKit

struct RunningView: View {
    @StateObject private var rundjService = RunDJService.shared
    @StateObject private var spotifyManager = SpotifyManager.shared
    @StateObject private var pedometerManager = PedometerManager.shared
    @StateObject private var runManager = RunManager.shared
    @StateObject private var runningStatsManager = RunningStatsManager.shared
    @StateObject private var liveActivityManager = LiveActivityManager.shared
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
    @State private var liveActivityUpdateTimer: Timer?
    @State private var allAvailableSongs: [String: Double] = [:]
    @State private var unqueuedSongIds: [String] = []
    @State private var isLoadingMoreSongs = false
    
    var bpm: Double
    
    var body: some View {
        ZStack {
            Color.rundjBackground
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Spotify Connection Section
                SpotifyConnectionPromptView(
                    spotifyManager: spotifyManager,
                    onRefreshSongs: refreshSongsBasedOnSettings
                )
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
                RunStatsCompactView(pedometerManager: pedometerManager, runningStatsManager: runningStatsManager, isRunning: isRunning)
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
            setupLiveActivityObservers()
        }
        .onDisappear {
            liveActivityUpdateTimer?.invalidate()
        }
        .onChange(of: isRunning) { _, newValue in
            if newValue {
                startLiveActivity()
                startLiveActivityUpdateTimer()
                showConfirmationMessage("Run started! Let's go! 🏃", color: .rundjMusicGreen)
            } else {
                endLiveActivity()
                stopLiveActivityUpdateTimer()
                showConfirmationMessage("Run complete! Great job! 💪", color: .rundjAccent)
            }
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
            
            // Register user and handle new/existing user logic
            rundjService.register(accessToken: token) { isNewUser in
                DispatchQueue.main.async {
                    if let isNewUser = isNewUser {
                        if isNewUser {
                            self.showConfirmationMessage("Setting up your account... Please wait a few minutes and reconnect.", color: .rundjAccent)
                            
                            self.spotifyManager.disconnect()
                            
                            self.spotifyErrorMessage = "Welcome to RunDJ! We're setting up your music preferences. This usually takes 2-3 minutes but is only necessary the first time you use the app. Take time to explore the app and help pages then reconnect to Spotify."
                            self.showSpotifyErrorAlert = true
                            
                            SentrySDK.capture(message: "New user registration - disconnecting for backend processing") { scope in
                                scope.setLevel(.info)
                            }
                        } else {
                            self.refreshSongsBasedOnSettings()
                        }
                    } else {
                        self.spotifyErrorMessage = "Failed to register. Please try reconnecting to Spotify."
                        self.showSpotifyErrorAlert = true
                        
                        SentrySDK.capture(message: "User registration failed") { scope in
                            scope.setLevel(.error)
                        }
                    }
                }
            }
        case .disconnected:
            isPlaylistButtonDisabled = true
        }
    }
    
    private func setupOnAppear() {
        // Set up auto-queue callback
        spotifyManager.onQueueLow = { [weak self] in
            self?.queueMoreSongs()
        }
        
        if spotifyManager.connectionState == .connected {
            refreshSongsBasedOnSettings()
            isPlaylistButtonDisabled = false
        } else {
            isPlaylistButtonDisabled = true
        }
    }
    
    private func handleSpotifyError(_ error: Error, message: String) {
        spotifyErrorMessage = "\(message)\nDetails: \(error.localizedDescription)"
        showSpotifyErrorAlert = true
        SentrySDK.capture(error: error) { scope in
            scope.setContext(value: ["user_action_message": message], key: "spotify_action_error")
        }
    }
    
    func refreshSongsBasedOnSettings() {
        guard spotifyManager.connectionState == .connected else {
            return
        }
        showConfirmationMessage("Flushing queue, please wait...", color: .rundjAccent)
        
        rundjService.getSongsByBPM(accessToken: token, bpm: bpm, sources: settingsManager.musicSources) { fetchedSongs in
            DispatchQueue.main.async {
                if fetchedSongs.isEmpty {
                    self.showConfirmationMessage("No songs found", color: .rundjWarning)
                } else {
                    // Store all available songs
                    self.allAvailableSongs = fetchedSongs
                    self.unqueuedSongIds = Array(fetchedSongs.keys).shuffled()
                    
                    Task {
                        await self.spotifyManager.flushQueue()
                        
                        // Queue first batch of 10 songs
                        let firstBatch = self.getNextBatchOfSongs(count: 10)
                        if !firstBatch.isEmpty {
                            await self.spotifyManager.queueSongs(firstBatch)
                            self.showConfirmationMessage("\(firstBatch.count) of \(fetchedSongs.count) songs queued!", color: .rundjMusicGreen)
                        }
                    }
                }
            }
        }
    }
    
    func queueMoreSongs() {
        guard !isLoadingMoreSongs, !unqueuedSongIds.isEmpty else {
            return
        }
        
        isLoadingMoreSongs = true
        let nextBatch = getNextBatchOfSongs(count: 10)
        
        if !nextBatch.isEmpty {
            Task {
                await spotifyManager.queueSongs(nextBatch, skipAfterFirst: false)
                DispatchQueue.main.async {
                    self.isLoadingMoreSongs = false
                    self.showConfirmationMessage("\(nextBatch.count) more songs added!", color: .rundjMusicGreen)
                }
            }
        } else {
            isLoadingMoreSongs = false
        }
    }
    
    private func getNextBatchOfSongs(count: Int) -> [String: Double] {
        var batch: [String: Double] = [:]
        let songsToTake = min(count, unqueuedSongIds.count)
        
        for _ in 0..<songsToTake {
            if let songId = unqueuedSongIds.first {
                unqueuedSongIds.removeFirst()
                if let bpm = allAvailableSongs[songId] {
                    batch[songId] = bpm
                }
            }
        }
        
        return batch
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
    
    // MARK: - Live Activity Functions
    
    private func startLiveActivity() {
        Task {
            do {
                try await liveActivityManager.startActivity(targetBPM: Int(bpm))
            } catch {
                SentrySDK.capture(error: error) { scope in
                    scope.setContext(value: ["targetBPM": bpm], key: "live_activity")
                    scope.setLevel(.warning)
                }
            }
        }
    }
    
    private func updateLiveActivity() {
        Task {
            // Format pace properly for live activity
            let paceString = runningStatsManager.currentPace < 0 ? "--:--" : runningStatsManager.formatPace(runningStatsManager.currentPace)
            
            await liveActivityManager.updateActivity(
                stepsPerMinute: Int(pedometerManager.stepsPerMinute),
                distance: runningStatsManager.totalDistance / 1609.34, // Convert meters to miles
                duration: runningStatsManager.totalElapsedTime,
                pace: paceString,
                currentSong: spotifyManager.currentlyPlaying.isEmpty ? "No song playing" : spotifyManager.currentlyPlaying,
                currentArtist: spotifyManager.currentArtist.isEmpty ? "--" : spotifyManager.currentArtist,
                songBPM: Int(spotifyManager.currentBPM),
                isPlaying: spotifyManager.isPlaying
            )
        }
    }
    
    private func endLiveActivity() {
        Task {
            await liveActivityManager.endActivity()
        }
    }
    
    private func startLiveActivityUpdateTimer() {
        liveActivityUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateLiveActivity()
        }
    }
    
    private func stopLiveActivityUpdateTimer() {
        liveActivityUpdateTimer?.invalidate()
        liveActivityUpdateTimer = nil
    }
    
    private func setupLiveActivityObservers() {
        NotificationCenter.default.addObserver(
            forName: .liveActivityThumbsUp,
            object: nil,
            queue: .main
        ) { _ in
            guard !self.spotifyManager.currentId.isEmpty else { return }
            self.isThumbsUpSelected = true
            self.isThumbsDownSelected = false
            self.showConfirmationMessage("Liked!", color: .rundjMusicGreen)
            self.rundjService.sendFeedback(accessToken: self.token, songId: self.spotifyManager.currentId, feedback: "LIKE") { success in
                if !success {
                    DispatchQueue.main.async {
                        self.isThumbsUpSelected = false
                        self.showConfirmationMessage("Failed to like", color: .rundjError)
                    }
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .liveActivityThumbsDown,
            object: nil,
            queue: .main
        ) { _ in
            guard !self.spotifyManager.currentId.isEmpty else { return }
            self.isThumbsDownSelected = true
            self.isThumbsUpSelected = false
            self.showConfirmationMessage("Skipping...", color: .rundjWarning)
            Task {
                async let skipTask: () = self.spotifyManager.skipToNextTrack()
                await self.rundjService.sendFeedback(accessToken: self.token, songId: self.spotifyManager.currentId, feedback: "DISLIKE") { _ in }
                do { 
                    try await skipTask 
                } catch {
                    DispatchQueue.main.async { 
                        self.handleSpotifyError(error, message: "Failed to skip.")
                    }
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .liveActivityStopRun,
            object: nil,
            queue: .main
        ) { _ in
            self.isRunning = false
            self.runManager.stop()
            self.endLiveActivity()
        }
    }
}

// MARK: - Compact View Components

struct SpotifyConnectionPromptView: View {
    @ObservedObject var spotifyManager: SpotifyManager
    let onRefreshSongs: () -> Void  // Add this callback
    
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
                case .connected:
                    onRefreshSongs()
                }
            }) {
                Text(connected ? "Refresh Songs" : "Connect Spotify")
            }
            .buttonStyle(RundjPrimaryButtonStyle(isMusic: true))
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
                Spacer()
                if spotifyManager.queuedSongsCount > 0 {
                    Text("\(spotifyManager.queuedSongsCount) songs in queue")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(spotifyManager.queuedSongsCount <= 10 ? .rundjWarning : .rundjTextSecondary)
                }
            }
            
            if !spotifyManager.hasQueuedSongs && spotifyManager.connectionState == .connected {
                Text("Queueing Songs...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.rundjWarning)
                
                Text("Please wait")
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
                    Text("\(String(format: "%.1f", spotifyManager.currentBPM)) BPM")
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
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
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
                    .rotationEffect(.degrees(isRunning ? 0 : 0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isRunning)
                Text(isRunning ? "Stop Run" : "Start Run")
                    .font(.system(size: 16, weight: .semibold))
            }
        }
        .buttonStyle(RundjPrimaryButtonStyle(isDisabled: false))
        .padding(.vertical, 8)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct RunStatsCompactView: View {
    @ObservedObject var pedometerManager: PedometerManager
    @ObservedObject var runningStatsManager: RunningStatsManager
    @State private var pulseAnimation = false
    let isRunning: Bool
    
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
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.rundjMusicGreen, lineWidth: 2)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .opacity(pulseAnimation ? 0 : 1)
                    .animation(pulseAnimation ? .easeOut(duration: 0.6) : .none, value: pulseAnimation)
                    .opacity(isRunning ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: isRunning)
            )
            .onChange(of: runningStatsManager.totalElapsedTime) { oldValue, newValue in
                if oldValue == 0 && newValue > 0 {
                    // Run just started
                    pulseAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        pulseAnimation = false
                    }
                }
            }
            
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
