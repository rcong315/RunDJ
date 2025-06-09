//
//  SpotifyManager.swift
//  RunDJ
//
//  Created by Richard Cong on 2/16/25.
//

import SpotifyiOS
import Sentry

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
    
    private var songMap = [String: Double]()
    private var isSkipping = false
    
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
            print("Keychain ERROR: Failed to convert \(key) to Data")
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
        if status == errSecSuccess {
            print("Keychain SUCCESS: Saved \(key) to Keychain")
        } else {
            print("Keychain ERROR: Failed saving \(key) to Keychain: \(status) - \(describeKeychainError(status))")
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
            print("Keychain SUCCESS: Loaded \(key) (length: \(string.count))")
            return string
        } else {
            if status == errSecItemNotFound {
                print("Keychain INFO: Item \(key) not found in Keychain")
            } else {
                print("Keychain ERROR: Failed loading \(key) from Keychain: \(status) - \(describeKeychainError(status))")
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
            print("Keychain ERROR: Failed deleting \(key) from Keychain: \(status) - \(describeKeychainError(status))")
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
            print("Keychain ERROR: Failed to load date for \(key)")
            return nil
        }
        
        guard let timestamp = Double(timestampString) else {
            print("Keychain ERROR: Failed to parse date for \(key)")
            SentrySDK.capture(message: "Keychain date parsing failed") { scope in
                scope.setContext(value: ["key": key, "timestamp_string": timestampString], key: "keychain_error")
                scope.setLevel(.error)
            }
            return nil
        }
        let date = Date(timeIntervalSince1970: timestamp)
        print("Keychain INFO: Loaded date \(date) for key \(key)")
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
            config.playURI = "spotify:track:2HHtWyy5CgaQbC7XSoOb0e" // Eye of the Tiger
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
        print("Initiating Spotify session...")
        
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
        print("Renewing Spotify session...")
        sessionManager.renewSession()
    }
    
    func disconnect() {
        if appRemote.isConnected {
            print("Disconnecting Spotify App Remote.")
            appRemote.disconnect()
        }
    }
    
    func handleURL(_ url: URL) {
        print("Handling Spotify URL: \(url)")
        let handled = sessionManager.application(UIApplication.shared, open: url)
        print("URL handled by session manager: \(handled)")
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
            print("Spotify not connected for \(actionDescription).")
            throw SpotifyError.notConnected
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let playerAPI = appRemote.playerAPI else {
                print("PlayerAPI not available for \(actionDescription).")
                continuation.resume(throwing: SpotifyError.notConnected)
                return
            }
            
            apiCall(playerAPI) { _, originalSDKError in
                if let sdkError = originalSDKError {
                    print("Error during \(actionDescription): \(sdkError.localizedDescription)")
                    var context = sentryContext
                    context["action_description"] = actionDescription
                    SentrySDK.capture(error: sdkError) { scope in
                        scope.setContext(value: context, key: "spotify_action_failure")
                        scope.setLevel(sentryLevel)
                    }
                    continuation.resume(throwing: errorBuilder(sdkError))
                } else {
                    print("\(actionDescription) successful.")
                    onSuccess?()
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - Async Playback Controls (Using Helper)
    
    @MainActor
    func play(uri: String) async throws {
        print("Attempting to play URI: \(uri)")
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
        print("Attempting to resume playback.")
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
        print("Attempting to pause playback.")
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
        print("Attempting to skip to next track.")
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
    func rewindTrack() async throws {
        print("Attempting to rewind track.")
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
        print("Attempting to enqueue track URI: \(uri)")
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
        print("Attempting to turn off repeat mode.")
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
    func queueSongs(_ songs: [String: Double]) async {
        self.songMap = songs // songMap maps track ID to BPM (ensure keys are IDs if URI used in playerStateDidChange)
        print("Queue received \(songs.count) songs. Shuffling and enqueuing...")
        if !self.songMap.isEmpty {
            self.hasQueuedSongs = true
            for songId in self.songMap.keys.shuffled() {
                do {
                    try await self.enqueueTrack(id: songId) // Uses the refactored enqueueTrack
                } catch {
                    print("Failed to enqueue song \(songId): \(error.localizedDescription)")
                    // Sentry logging is handled within enqueueTrack
                }
            }
        } else {
            print("Queue initialized with empty song list.")
            self.hasQueuedSongs = false
        }
        do {
            try await skipToNextTrack()
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.setContext(value: ["action": "skip_after_queueing", "song_count": songs.count], key: "spotify_queue")
                scope.setLevel(.warning)
            }
        }
    }
    
    @MainActor
    func flushQueue() async {
        guard appRemote.isConnected, appRemote.playerAPI != nil else {
            print("Cannot flush queue: Spotify not connected or player API unavailable.")
            return
        }
        print("Attempting to flush queue...")
        let placeholderTrackId = "2bNCdW4rLnCTzgqUXTTDO1"
        var skips = 0
        let maxSkips = 100
        
        do {
            try await enqueueTrack(id: placeholderTrackId) // Uses refactored method
            print("Placeholder track enqueued. Now skipping to it.")
            
            while currentId != placeholderTrackId && skips < maxSkips {
                if !isSkipping {
                    print("Flushing queue: Skip attempt \(skips + 1)")
                    try await skipToNextTrack() // Uses refactored method
                    try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s delay for state update
                    skips += 1
                } else {
                    try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s delay if already skipping
                }
            }
            
            if currentId == placeholderTrackId {
                print("Reached placeholder track. Skipping one more time to clear it.")
                try await skipToNextTrack() // Uses refactored method
                print("Queue flush attempt complete.")
            } else {
                print("Failed to reliably reach placeholder track after \(skips) skips. Current ID: \(currentId)")
                SentrySDK.capture(message: "Queue flush failed - placeholder track not reached") { scope in
                    scope.setContext(value: [
                        "skips_attempted": skips,
                        "current_id": self.currentId,
                        "placeholder_id": placeholderTrackId
                    ], key: "queue_flush")
                    scope.setLevel(.warning)
                }
            }
        } catch {
            print("Error during queue flush: \(error.localizedDescription)")
            SentrySDK.capture(error: error) { scope in
                scope.setContext(value: ["action": "queue_flush"], key: "spotify_queue")
                scope.setLevel(.error)
            }
        }
        self.songMap.removeAll()
        self.hasQueuedSongs = false
    }
    
    
    // MARK: - SPTSessionManagerDelegate
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("Session initiated")
        print("Refresh Token: \(session.refreshToken)")
        print("Access Token: \(session.accessToken)")
        print("Expiration Date: \(session.expirationDate)")
        
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
        print("Session renewed")
        print("Access Token: \(session.accessToken)")
        print("Expiration Date: \(session.expirationDate)")
        
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
        print("Session failed with error: \(error)")
        print("Error domain: \(error._domain)")
        print("Error code: \(error._code)")
        
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
        print("Connected to Spotify")
        DispatchQueue.main.async {
            self.connectionState = .connected
        }
        
        print("Setting up player API")
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { [weak self] result, error in
            if let error = error {
                print("Player subscription error: \(error)")
                SentrySDK.capture(error: error) { scope in
                    scope.setContext(value: ["action": "subscribe_to_player_state"], key: "spotify_connection")
                    scope.setLevel(.error)
                }
                DispatchQueue.main.async {
                    self?.connectionState = .error("Player subscription error: \(error.localizedDescription)")
                }
            } else {
                print("Successfully subscribed to player state")
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
        print("Disconnected from Spotify")
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            self.appRemote.connect()
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Connection attempt failed with error: \(String(describing: error))")
        
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
            print("Disconnected with error: \(error)")
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
        print("Player state changed")
        DispatchQueue.main.async {
            self.currentlyPlaying = playerState.track.name
            self.currentArtist = playerState.track.artist.name
            self.isPlaying = !playerState.isPaused
            let components = playerState.track.uri.split(separator: ":")
            if let trackId = components.last {
                let idToSet = String(trackId)
                self.currentId = idToSet
                self.currentBPM = self.songMap[self.currentId] ?? 0.0
            }
        }
    }
}
