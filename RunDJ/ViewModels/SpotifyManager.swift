//
//  SpotifyManager.swift
//  RunDJ
//
//  Created by Richard Cong on 2/16/25.
//

import SpotifyiOS
import Sentry
import SwiftUI

/// Manages Spotify interactions including authentication, playback, and song queuing
class SpotifyManager: NSObject, ObservableObject, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate, SPTSessionManagerDelegate {
    
    static let shared = SpotifyManager()
    
    private let clientID = Configuration.spotifyClientID
    private let redirectURI = Configuration.spotifyRedirectURI
    private let serverURL = Configuration.serverBaseURL
    
    private let keychainServiceName = "com.rundj.spotifyauth"
    private let refreshTokenKey = "spotify_refresh_token"
    private let accessTokenKey = "spotify_access_token"
    private let expirationDateKey = "spotify_expiration_date"
    
    @Published var currentlyPlaying: String = ""
    @Published var currentId: String = ""
    @Published var currentArtist: String = ""
    @Published var currentBPM: Double = 0.0
    @Published var connectionState: ConnectionState = .disconnected
    @Published var isPlaying: Bool = false
    @Published var hasQueuedSongs: Bool = false
    @Published var queuedSongsCount: Int = 0
    
    private var songMap = [String: Double]()
    private var isSkipping = false
    private var queuedSongIds = Set<String>()
    private var playedSongIds = Set<String>()
        
    enum ConnectionState: Equatable {
        case connected
        case disconnected
        case error(String)
        
        static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
            switch (lhs, rhs) {
            case (.connected, .connected): return true
            case (.disconnected, .disconnected): return true
            case (.error(let lhsError), .error(let rhsError)): return lhsError == rhsError
            default: return false
            }
        }
    }
    
    enum SpotifyError: LocalizedError {
        case notConnected
        case playbackFailed(String)
        case enqueueFailed(String)
        case unknownError
        
        var errorDescription: String? {
            switch self {
            case .notConnected:
                return "Spotify is not connected"
            case .playbackFailed(let message):
                return "Playback failed: \(message)"
            case .enqueueFailed(let message):
                return "Failed to enqueue track: \(message)"
            case .unknownError:
                return "An unknown error occurred"
            }
        }
    }
    
    // MARK: - Token Management
    
    private var refreshToken: String? {
        get {
            return loadFromKeychain(key: refreshTokenKey)
        }
        set {
            if let newValue = newValue {
                saveToKeychain(key: refreshTokenKey, data: newValue)
            } else {
                deleteFromKeychain(key: refreshTokenKey)
            }
        }
    }
    
    private var accessToken: String? {
        get {
            return loadFromKeychain(key: accessTokenKey)
        }
        set {
            if let newValue = newValue {
                saveToKeychain(key: accessTokenKey, data: newValue)
                // Update the access token for the app remote connection
                appRemote.connectionParameters.accessToken = newValue
            } else {
                deleteFromKeychain(key: accessTokenKey)
            }
        }
    }
    
    private var tokenExpirationDate: Date? {
        get {
            return loadDateFromKeychain(key: expirationDateKey)
        }
        set {
            if let newValue = newValue {
                saveDateToKeychain(key: expirationDateKey, date: newValue)
            } else {
                deleteFromKeychain(key: expirationDateKey)
            }
        }
    }
    
    private var isTokenValid: Bool {
        guard let expirationDate = tokenExpirationDate,
              let _ = accessToken else {
            return false
        }
        
        // Add a 5-minute buffer to ensure we don't use tokens that are about to expire
        return expirationDate.timeIntervalSinceNow > 300
    }
    
    func getAccessToken() -> String? {
        return accessToken
    }
    
    // MARK: - Keychain Methods
    
    private func saveToKeychain(key: String, data: String) {
        // Delete any existing item
        deleteFromKeychain(key: key)
        
        guard let dataToStore = data.data(using: .utf8) else {
            SentrySDK.capture(message: "Keychain data conversion failed") { scope in
                scope.setContext(value: ["key": key], key: "keychain_error")
                scope.setLevel(.error)
            }
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: dataToStore,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            SentrySDK.capture(message: "Keychain save failed") { scope in
                scope.setContext(value: ["key": key, "status": status, "error_description": self.describeKeychainError(status)], key: "keychain_error")
                scope.setLevel(.error)
            }
        }
    }
    
    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data, let string = String(data: data, encoding: .utf8) {
            return string
        } else {
            if status != errSecItemNotFound {
                SentrySDK.capture(message: "Keychain load failed") { scope in
                    scope.setContext(value: ["key": key, "status": status, "error_description": self.describeKeychainError(status)], key: "keychain_error")
                    scope.setLevel(.warning)
                }
            }
            return nil
        }
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainServiceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound{
            SentrySDK.capture(message: "Keychain delete failed") { scope in
                scope.setContext(value: ["key": key, "status": status, "error_description": self.describeKeychainError(status)], key: "keychain_error")
                scope.setLevel(.warning)
            }
        }
    }
    
    private func saveDateToKeychain(key: String, date: Date) {
        let timestamp = date.timeIntervalSince1970
        saveToKeychain(key: key, data: String(timestamp))
    }
    
    private func loadDateFromKeychain(key: String) -> Date? {
        guard let timestampString = loadFromKeychain(key: key) else {
            return nil
        }
        
        guard let timestamp = Double(timestampString) else {
            SentrySDK.capture(message: "Keychain date parsing failed") { scope in
                scope.setContext(value: ["key": key, "timestamp_string": timestampString], key: "keychain_error")
                scope.setLevel(.error)
            }
            return nil
        }
        let date = Date(timeIntervalSince1970: timestamp)
        return date
    }
    
    private func describeKeychainError(_ status: OSStatus) -> String {
        switch status {
        case errSecSuccess:
            return "No error"
        case errSecUnimplemented:
            return "Function not implemented"
        case errSecParam:
            return "Parameter error"
        case errSecAllocate:
            return "Failed to allocate memory"
        case errSecNotAvailable:
            return "No trust results available"
        case errSecAuthFailed:
            return "Authorization/Authentication failed"
        case errSecDuplicateItem:
            return "Item already exists"
        case errSecItemNotFound:
            return "Item not found"
        case errSecInteractionNotAllowed:
            return "Interaction with the Security Server not allowed"
        case errSecDecode:
            return "Unable to decode the provided data"
        case errSecDiskFull:
            return "The disk is full"
        default:
            return "Unknown error (\(status))"
        }
    }
    
    // MARK: - Configuration
    
    lazy var configuration: SPTConfiguration = {
        let config = SPTConfiguration(clientID: clientID, redirectURL: URL(string: redirectURI)!)
        
        if let tokenSwapURL = URL(string: "\(serverURL)/api/v1/spotify/auth/token"),
           let tokenRefreshURL = URL(string: "\(serverURL)/api/v1/spotify/auth/refresh") {
            config.tokenSwapURL = tokenSwapURL
            config.tokenRefreshURL = tokenRefreshURL
            config.playURI = "spotify:track:7depNAqAh1r9unkIRzibID" // Dummy track
        }
        
        return config
    }()
    
    lazy var sessionManager: SPTSessionManager = {
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        return manager
    }()
    
    lazy var appRemote: SPTAppRemote = {
        let remote = SPTAppRemote(configuration: configuration, logLevel: .info)
        remote.delegate = self
        return remote
    }()
    
    // MARK: - Authentication Flow
    
    func initiateSession() {
        if appRemote.isConnected {
            disconnect()
        }
        
        let scopes: SPTScope = [
            .appRemoteControl,
            .streaming,
            
                .userReadPlaybackState,
            .userModifyPlaybackState,
            .userReadCurrentlyPlaying,
            .userReadRecentlyPlayed,
            
                .userReadEmail,
            .userReadPrivate,
            
                .userTopRead,
            .userLibraryRead,
            //            .userLibraryModify,
            .userFollowRead,
            //            .userFollowModify,
            
                .playlistReadPrivate,
            .playlistReadCollaborative,
            //            .playlistModifyPublic,
            .playlistModifyPrivate,
        ]
        
        sessionManager.initiateSession(with: scopes, options: .default, campaign: "Run DJ")
    }
    
    func renewSession() {
        sessionManager.renewSession()
    }
    
    func disconnect() {
        if appRemote.isConnected {
            appRemote.disconnect()
        }
    }
    
    func handleURL(_ url: URL) {
        sessionManager.application(UIApplication.shared, open: url)
    }
    
    // MARK: - Playback Controls Helper
    
    @MainActor
    private func performPlayerAPICall(
        actionDescription: String,
        sentryContext: [String: Any] = [:],
        sentryLevel: SentryLevel = .warning,
        apiCall: @escaping (SPTAppRemotePlayerAPI, @escaping SPTAppRemoteCallback) -> Void,
        onSuccess: (() -> Void)? = nil,
        errorBuilder: @escaping (Error) -> Error
    ) async throws {
        guard appRemote.isConnected else {
            throw SpotifyError.notConnected
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let playerAPI = appRemote.playerAPI else {
                continuation.resume(throwing: SpotifyError.notConnected)
                return
            }
            
            apiCall(playerAPI) { _, originalSDKError in
                if let sdkError = originalSDKError {
                    var context = sentryContext
                    context["action_description"] = actionDescription
                    SentrySDK.capture(error: sdkError) { scope in
                        scope.setContext(value: context, key: "spotify_action_failure")
                        scope.setLevel(sentryLevel)
                    }
                    continuation.resume(throwing: errorBuilder(sdkError))
                } else {
                    onSuccess?()
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - Async Playback Controls (Using Helper)
    
    @MainActor
    func play(uri: String) async throws {
        try await performPlayerAPICall(
            actionDescription: "play track",
            sentryContext: ["uri": uri],
            sentryLevel: .error,
            apiCall: { playerAPI, callback in
                playerAPI.play(uri, callback: callback)
            },
            onSuccess: { [weak self] in
                self?.isSkipping = false // Reset isSkipping if a direct play occurs
            },
            errorBuilder: { sdkError in SpotifyError.playbackFailed("Playing track failed: \(sdkError.localizedDescription)") }
        )
    }
    
    @MainActor
    func resumePlayback() async throws {
        try await performPlayerAPICall(
            actionDescription: "resume playback",
            sentryLevel: .warning,
            apiCall: { playerAPI, callback in
                playerAPI.resume(callback)
            },
            errorBuilder: { sdkError in SpotifyError.playbackFailed("Resuming playback failed: \(sdkError.localizedDescription)") }
        )
    }
    
    @MainActor
    func pausePlayback() async throws {
        try await performPlayerAPICall(
            actionDescription: "pause playback",
            sentryLevel: .warning,
            apiCall: { playerAPI, callback in
                playerAPI.pause(callback)
            },
            errorBuilder: { sdkError in SpotifyError.playbackFailed("Pausing playback failed: \(sdkError.localizedDescription)") }
        )
    }
    
    @MainActor
    func skipToNextTrack() async throws {
        isSkipping = true // Set before the async operation begins
        
        do {
            try await performPlayerAPICall(
                actionDescription: "skip to next track",
                sentryLevel: .warning,
                apiCall: { playerAPI, callback in
                    playerAPI.skip(toNext: callback)
                },
                onSuccess: { [weak self] in
                    self?.isSkipping = false
                },
                errorBuilder: { [weak self] sdkError in
                    self?.isSkipping = false // Ensure reset on SDK error
                    return SpotifyError.playbackFailed("Skipping to next track failed: \(sdkError.localizedDescription)")
                }
            )
        } catch {
            isSkipping = false // Ensure reset if performPlayerAPICall throws before SDK callback
            throw error
        }
    }
    
    @MainActor
    func skipToNextTrackAndWaitForStateChange() async throws {
        let currentTrackId = currentId
        try await skipToNextTrack()
        
        // Wait for the state to actually change
        await waitForTrackChange(from: currentTrackId, timeout: 5.0)
    }
    
    @MainActor
    private func waitForTrackChange(from previousId: String, timeout: TimeInterval) async {
        let startTime = Date()
        
        while currentId == previousId && Date().timeIntervalSince(startTime) < timeout {
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.1s polling interval
        }
        
        if currentId == previousId {
            SentrySDK.capture(message: "Track state did not change after skip") { scope in
                scope.setContext(value: [
                    "previous_id": previousId,
                    "current_id": self.currentId,
                    "timeout": timeout
                ], key: "skip_state_timeout")
                scope.setLevel(.warning)
            }
        }
    }
    
    @MainActor
    func rewindTrack() async throws {
        try await performPlayerAPICall(
            actionDescription: "rewind track",
            sentryLevel: .warning,
            apiCall: { playerAPI, callback in
                playerAPI.seek(toPosition: 0, callback: callback)
            },
            errorBuilder: { sdkError in SpotifyError.playbackFailed("Rewinding track failed: \(sdkError.localizedDescription)") }
        )
    }
    
    @MainActor
    func enqueueTrack(id: String) async throws {
        let uri = "spotify:track:\(id)"
        try await performPlayerAPICall(
            actionDescription: "enqueue track",
            sentryContext: ["uri": uri],
            sentryLevel: .warning,
            apiCall: { playerAPI, callback in
                playerAPI.enqueueTrackUri(uri, callback: callback)
            },
            errorBuilder: { sdkError in SpotifyError.enqueueFailed("Enqueuing track \(uri) failed: \(sdkError.localizedDescription)") }
        )
    }
    
    @MainActor
    func turnOffRepeat() async throws {
        try await performPlayerAPICall(
            actionDescription: "turn off repeat mode",
            sentryLevel: .info, // Setting repeat mode might be less critical
            apiCall: { playerAPI, callback in
                playerAPI.setRepeatMode(.off, callback: callback)
            },
            errorBuilder: { sdkError in SpotifyError.playbackFailed("Turning off repeat failed: \(sdkError.localizedDescription)") }
        )
    }
    
    // MARK: - Other MainActor methods
    // These methods have more complex logic than simple API calls and might not use the helper directly,
    // or might use it internally for sub-steps if applicable.
    @MainActor
    func queueSongs(_ songs: [String: Double], skipAfterFirst: Bool = true, allowRequeue: Bool = false) async {
        // Note: songMap should already contain all songs from initializeSongBatching
        // This method now only queues the specific batch of songs passed to it
        
        // Log queueing attempt for debugging
        let breadcrumb = Breadcrumb(level: .info, category: "spotify_queue")
        breadcrumb.message = "Attempting to queue \(songs.count) songs"
        breadcrumb.data = [
            "song_count": songs.count,
            "skip_after_first": skipAfterFirst,
            "already_queued_count": queuedSongIds.count
        ]
        SentrySDK.addBreadcrumb(breadcrumb)
        
        if !songs.isEmpty {
            self.hasQueuedSongs = true
            let songIds = Array(songs.keys)
            var enqueuedCount = 0
            var shouldSkip = skipAfterFirst
            
            for songId in songIds {
                // Skip if already queued (unless we explicitly allow requeueing)
                if queuedSongIds.contains(songId) && !allowRequeue {
                    continue
                }
                
                do {
                    try await self.enqueueTrack(id: songId)
                    queuedSongIds.insert(songId)
                    enqueuedCount += 1
                    
                    // Always increment the actual queue count when we successfully queue a song
                    queuedSongsCount += 1
                    
                    // Log queue count for debugging
                    let queueBreadcrumb = Breadcrumb(level: .info, category: "spotify_queue")
                    queueBreadcrumb.message = "Song queued successfully - count now: \(queuedSongsCount)"
                    queueBreadcrumb.data = [
                        "song_id": songId,
                        "queue_count": queuedSongsCount,
                        "allow_requeue": allowRequeue
                    ]
                    SentrySDK.addBreadcrumb(queueBreadcrumb)
                    
                    // Skip after first song is successfully queued
                    if shouldSkip && enqueuedCount == 1 {
                        shouldSkip = false
                        do {
                            try await skipToNextTrackAndWaitForStateChange()
                        } catch {
                            SentrySDK.capture(error: error) { scope in
                                scope.setContext(value: ["action": "skip_after_first_enqueue"], key: "spotify_queue")
                                scope.setLevel(.warning)
                            }
                        }
                    }
                } catch {
                    // Continue queueing even if one fails
                }
            }
            
            // Check if we need to queue more songs after this batch
            updateQueuedSongsCount()
        } else {
            self.hasQueuedSongs = false
        }
    }
    
    private func updateQueuedSongsCount() {
        // When a song is played, decrement the count
        // Note: queuedSongsCount is now manually tracked when songs are queued
        
        if queuedSongsCount <= 5 && queuedSongsCount > 0 {
            // Auto-queue more songs using the new batching system
            Task {
                await queueMoreSongs()
            }
        }
    }
    
    @MainActor
    func flushQueue() async {
        guard appRemote.isConnected, appRemote.playerAPI != nil else {
            return
        }
        let placeholderTrackId = "5kiJ9x6eX37H5J9lyyXkua"
        var skips = 0
        let maxSkips = 50 // Reduced from 100 to prevent excessive skipping
        
        do {
            try await enqueueTrack(id: placeholderTrackId)
            
            // Give a brief moment for the track to be available in queue
            try await Task.sleep(nanoseconds: 100_000_000) // 0.5s initial delay
            
            while currentId != placeholderTrackId && skips < maxSkips {
                if !isSkipping {
                    try await skipToNextTrackAndWaitForStateChange()
                    skips += 1
                } else {
                    // Already skipping, wait a short time and check again
                    try await Task.sleep(nanoseconds: 50_000_000) // 0.1s delay while skipping
                }
            }
            
            // Final validation and cleanup
            if currentId == placeholderTrackId {
                // Successfully reached placeholder, skip past it
                try await skipToNextTrackAndWaitForStateChange()
            } else {
                SentrySDK.capture(message: "Queue flush failed - placeholder track not reached") { scope in
                    scope.setContext(value: [
                        "skips_attempted": skips,
                        "current_id": self.currentId,
                        "placeholder_id": placeholderTrackId,
                        "max_skips_reached": skips >= maxSkips
                    ], key: "queue_flush")
                    scope.setLevel(.warning)
                }
            }
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.setContext(value: [
                    "action": "queue_flush",
                    "skips_completed": skips
                ], key: "spotify_queue")
                scope.setLevel(.error)
            }
        }
        
        // Clean up state regardless of success/failure
        // Note: Don't clear songMap here as it contains BPM info for all available songs
        self.queuedSongIds.removeAll()
        self.playedSongIds.removeAll()
        self.queuedSongsCount = 0
        self.hasQueuedSongs = false
    }
    
    func clearPlayedSongs() {
        self.playedSongIds.removeAll()
        updateQueuedSongsCount()
    }
    
    /// Clear all song data (useful when switching BPM or sources)
    func clearAllSongData() {
        songMap.removeAll()
        allAvailableSongs.removeAll()
        unqueuedSongIds.removeAll()
        queuedSongIds.removeAll()
        playedSongIds.removeAll()
        queuedSongsCount = 0
        hasQueuedSongs = false
        isLoadingMoreSongs = false
    }
    
    // MARK: - Song Batching Management
    
    /// All available songs for the current BPM and sources
    @Published private(set) var allAvailableSongs: [String: Double] = [:]
    
    /// Songs that haven't been queued yet
    private var unqueuedSongIds: [String] = []
    
    /// Flag to prevent multiple concurrent batch loading operations
    private var isLoadingMoreSongs = false
    
    /// Callback for when more songs are needed
    var onSongsUpdated: (([String: Double]) -> Void)?
    
    /// Callback for status updates during the queueing process
    var onQueueStatusUpdate: ((String, Color) -> Void)?
    
    /// Initialize song batching with fetched songs
    /// - Parameter songs: Dictionary of song IDs to BPM values
    func initializeSongBatching(with songs: [String: Double]) {
        allAvailableSongs = songs
        songMap = songs // Ensure songMap contains all songs for BPM lookup
        unqueuedSongIds = Array(songs.keys).shuffled()
        isLoadingMoreSongs = false
    }
    
    /// Get the next batch of songs for queueing
    /// - Parameter count: Number of songs to include in the batch (default: 10)
    /// - Returns: Dictionary of song IDs to BPM values for the next batch
    func getNextBatchOfSongs(count: Int = 10) -> [String: Double] {
        var batch: [String: Double] = [:]
        let songsToTake = min(count, unqueuedSongIds.count)
        
        // Take songs from the beginning to maintain order
        let selectedSongIds = Array(unqueuedSongIds.prefix(songsToTake))
        unqueuedSongIds.removeFirst(songsToTake)
        
        // Build batch maintaining the order
        for songId in selectedSongIds {
            if let bpm = allAvailableSongs[songId] {
                batch[songId] = bpm
            }
        }
        
        return batch
    }
    
    /// Queue the initial batch of songs after flushing
    /// - Parameter count: Number of songs to queue initially (default: 10)
    @MainActor
    func queueInitialBatch(count: Int = 10) async {
        let firstBatch = getNextBatchOfSongs(count: count)
        if !firstBatch.isEmpty {
            await queueSongs(firstBatch)
            onSongsUpdated?(firstBatch)
        }
    }
    
    /// Automatically queue more songs when running low
    /// - Parameter count: Number of songs to add (default: 10)
    @MainActor
    func queueMoreSongs(count: Int = 10) async {
        guard !isLoadingMoreSongs else {
            let breadcrumb = Breadcrumb(level: .info, category: "spotify_queue")
            breadcrumb.message = "queueMoreSongs: Already loading, skipping"
            SentrySDK.addBreadcrumb(breadcrumb)
            return
        }
        
        // Log the state before processing
        let breadcrumb = Breadcrumb(level: .info, category: "spotify_queue")
        breadcrumb.message = "queueMoreSongs: Starting with \(unqueuedSongIds.count) unqueued songs"
        breadcrumb.data = [
            "unqueued_count": unqueuedSongIds.count,
            "total_available": allAvailableSongs.count,
            "requested_count": count
        ]
        SentrySDK.addBreadcrumb(breadcrumb)
        
        // Track if we need to reshuffle (ran out of unqueued songs)
        var needsReshuffle = false
        
        // If we've run out of unqueued songs, start a new loop by reshuffling all songs
        if unqueuedSongIds.isEmpty && !allAvailableSongs.isEmpty {
            let loopBreadcrumb = Breadcrumb(level: .info, category: "spotify_queue")
            loopBreadcrumb.message = "queueMoreSongs: Starting new loop - reshuffling all songs (including already queued ones)"
            loopBreadcrumb.data = ["total_songs": allAvailableSongs.count]
            SentrySDK.addBreadcrumb(loopBreadcrumb)
            
            unqueuedSongIds = Array(allAvailableSongs.keys).shuffled()
            needsReshuffle = true
            // Don't clear playedSongs here - we want to requeue songs even if they haven't been played yet
            onSongsUpdated?([:]) // Signal that we're starting a new loop
        }
        
        guard !unqueuedSongIds.isEmpty else {
            let emptyBreadcrumb = Breadcrumb(level: .warning, category: "spotify_queue")
            emptyBreadcrumb.message = "queueMoreSongs: No songs available to queue"
            emptyBreadcrumb.data = [
                "unqueued_count": unqueuedSongIds.count,
                "total_available": allAvailableSongs.count
            ]
            SentrySDK.addBreadcrumb(emptyBreadcrumb)
            return
        }
        
        isLoadingMoreSongs = true
        let nextBatch = getNextBatchOfSongs(count: count)
        
        if !nextBatch.isEmpty {
            let queueBreadcrumb = Breadcrumb(level: .info, category: "spotify_queue")
            queueBreadcrumb.message = "queueMoreSongs: Queueing \(nextBatch.count) songs (allowRequeue: \(needsReshuffle))"
            SentrySDK.addBreadcrumb(queueBreadcrumb)
            
            // Allow requeueing if we just reshuffled
            await queueSongs(nextBatch, skipAfterFirst: false, allowRequeue: needsReshuffle)
            onSongsUpdated?(nextBatch)
        } else {
            let emptyBatchBreadcrumb = Breadcrumb(level: .warning, category: "spotify_queue")
            emptyBatchBreadcrumb.message = "queueMoreSongs: getNextBatchOfSongs returned empty batch"
            SentrySDK.addBreadcrumb(emptyBatchBreadcrumb)
        }
        
        isLoadingMoreSongs = false
    }
    
    /// Get the total number of available songs
    var totalAvailableSongs: Int {
        return allAvailableSongs.count
    }
    
    /// Get the number of unqueued songs remaining
    var remainingUnqueuedSongs: Int {
        return unqueuedSongIds.count
    }
    
    /// Refresh songs and queue initial batch - handles the complete flow
    /// - Parameters:
    ///   - songs: Dictionary of song IDs to BPM values fetched from the API
    ///   - initialBatchSize: Number of songs to queue initially (default: 10)
    @MainActor
    func refreshSongsAndQueue(with songs: [String: Double], initialBatchSize: Int = 10) async {
        guard connectionState == .connected else {
            onQueueStatusUpdate?("Not connected to Spotify", .rundjError)
            return
        }
        
        if songs.isEmpty {
            onQueueStatusUpdate?("No songs found", .rundjWarning)
            return
        }
        
        // Update status
        onQueueStatusUpdate?("Flushing queue, please wait...", .rundjAccent)
        
        // Initialize batching system
        initializeSongBatching(with: songs)
        
        // Flush existing queue and queue initial batch
        await flushQueue()
        await queueInitialBatch(count: initialBatchSize)
        
        // Update status with success message
        onQueueStatusUpdate?("\(initialBatchSize) of \(songs.count) songs queued!", .rundjMusicGreen)
    }
    
    
    // MARK: - SPTSessionManagerDelegate
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        let breadcrumb = Breadcrumb()
        breadcrumb.level = .info
        breadcrumb.category = "spotify"
        breadcrumb.message = "Session initiated successfully"
        SentrySDK.addBreadcrumb(breadcrumb)
        
        refreshToken = session.refreshToken
        accessToken = session.accessToken
        tokenExpirationDate = session.expirationDate
        
        appRemote.connectionParameters.accessToken = session.accessToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.appRemote.connect()
        }
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        let breadcrumb = Breadcrumb()
        breadcrumb.level = .info
        breadcrumb.category = "spotify"
        breadcrumb.message = "Session renewed successfully"
        SentrySDK.addBreadcrumb(breadcrumb)
        
        accessToken = session.accessToken
        tokenExpirationDate = session.expirationDate
        
        appRemote.connectionParameters.accessToken = session.accessToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.appRemote.connect()
        }
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        SentrySDK.capture(error: error) { scope in
            scope.setContext(value: ["error_domain": error._domain, "error_code": error._code], key: "spotify_session")
            scope.setLevel(.error)
        }
        
        DispatchQueue.main.async {
            self.connectionState = .error("Session failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - SPTAppRemoteDelegate
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        DispatchQueue.main.async {
            self.connectionState = .connected
        }
        
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { [weak self] result, error in
            if let error = error {
                SentrySDK.capture(error: error) { scope in
                    scope.setContext(value: ["action": "subscribe_to_player_state"], key: "spotify_connection")
                    scope.setLevel(.error)
                }
                DispatchQueue.main.async {
                    self?.connectionState = .error("Player subscription error: \(error.localizedDescription)")
                }
            } else {
                let breadcrumb = Breadcrumb()
                breadcrumb.level = .info
                breadcrumb.category = "spotify"
                breadcrumb.message = "Successfully subscribed to player state"
                SentrySDK.addBreadcrumb(breadcrumb)
            }
        })
        //        pause()
    }
    
    func appRemoteDidDisconnect(_ appRemote: SPTAppRemote) {
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            self.appRemote.connect()
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        if let error = error {
            SentrySDK.capture(error: error) { scope in
                scope.setContext(value: ["action": "connection_attempt"], key: "spotify_connection")
                scope.setLevel(.error)
            }
        } else {
            SentrySDK.capture(message: "Spotify connection failed with unknown error") { scope in
                scope.setLevel(.error)
            }
        }
        
        DispatchQueue.main.async {
            self.connectionState = .error("Connection failed: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        if let error = error {
            SentrySDK.capture(error: error) { scope in
                scope.setContext(value: ["action": "disconnect"], key: "spotify_connection")
                scope.setLevel(.warning)
            }
        }
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        DispatchQueue.main.async {
            self.currentlyPlaying = playerState.track.name
            self.currentArtist = playerState.track.artist.name
            self.isPlaying = !playerState.isPaused
            let components = playerState.track.uri.split(separator: ":")
            if let trackId = components.last {
                let idToSet = String(trackId)
                let previousId = self.currentId
                self.currentId = idToSet
                // Try songMap first (contains all songs), fallback to allAvailableSongs if needed
                let bpmFromSongMap = self.songMap[self.currentId]
                let bpmFromAllSongs = self.allAvailableSongs[self.currentId]
                self.currentBPM = bpmFromSongMap ?? bpmFromAllSongs ?? 0.0
                
                // Log if BPM is missing for debugging
                if self.currentBPM == 0.0 && !self.currentId.isEmpty {
                    SentrySDK.capture(message: "BPM not found for current track") { scope in
                        scope.setContext(value: [
                            "track_id": self.currentId,
                            "track_name": self.currentlyPlaying,
                            "songMap_count": self.songMap.count,
                            "allAvailableSongs_count": self.allAvailableSongs.count,
                            "in_songMap": bpmFromSongMap != nil,
                            "in_allAvailableSongs": bpmFromAllSongs != nil
                        ], key: "bpm_lookup")
                        scope.setLevel(.warning)
                    }
                }
                
                // Track played songs and update count
                if previousId != idToSet && self.queuedSongIds.contains(previousId) {
                    self.playedSongIds.insert(previousId)
                    // Decrement the queue count when a song finishes playing
                    if self.queuedSongsCount > 0 {
                        self.queuedSongsCount -= 1
                        
                        // Log queue count change for debugging
                        let playBreadcrumb = Breadcrumb(level: .info, category: "spotify_queue")
                        playBreadcrumb.message = "Song played - count now: \(self.queuedSongsCount)"
                        playBreadcrumb.data = [
                            "played_song_id": previousId,
                            "new_song_id": idToSet,
                            "queue_count": self.queuedSongsCount
                        ]
                        SentrySDK.addBreadcrumb(playBreadcrumb)
                    }
                    self.updateQueuedSongsCount()
                }
            }
        }
    }
}
