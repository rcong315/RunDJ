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
    
    // MARK: - Keychain Methods
    
    private func saveToKeychain(key: String, data: String) {
        // Delete any existing item
        deleteFromKeychain(key: key)
        
        guard let dataToStore = data.data(using: .utf8) else {
            print("Keychain ERROR: Failed to convert \(key) to Data")
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
        guard let timestampString = loadFromKeychain(key: key),
              let timestamp = Double(timestampString) else {
            print("Keychain ERROR: Failed to parse date for \(key)")
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
    
    func initiateSession(completion: (() -> Void)? = nil) {
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
    
    func handleURL(_ url: URL) {
        print("Handling Spotify URL: \(url)")
        let handled = sessionManager.application(UIApplication.shared, open: url)
        print("URL handled by session manager: \(handled)")
    }
    
    // MARK: - Playback Controls
    
    /// Retrieve the current Spotify access token
    /// - Returns: The current access token or nil if not authenticated
    func getAccessToken() -> String? {
        return accessToken
    }
    
    /// Play a track with the given URI
    /// - Parameter uri: Spotify URI for the track to play
    func play(uri: String, completion: @escaping () -> Void) {
        print("Playing: \(uri)")
        appRemote.playerAPI?.play(uri, callback: { result, error in
            if let error = error {
                print("Error playing: \(error.localizedDescription)")
                SentrySDK.capture(error: error) { scope in
                    scope.setContext(value: ["uri": uri], key: "spotify_playback")
                    scope.setLevel(.error)
                }
            }
            self.isSkipping = false
        })
    }
    
    /// Resume playback of the current track
    func resume() {
        appRemote.playerAPI?.resume({ result, error in
            if let error = error {
                print("Error resuming playback: \(error)")
                SentrySDK.capture(error: error) { scope in
                    scope.setContext(value: ["action": "resume"], key: "spotify_playback")
                    scope.setLevel(.warning)
                }
            }
        })
    }
    
    /// Pause the currently playing track
    func pause() {
        appRemote.playerAPI?.pause({ result, error in
            if let error = error {
                print("Error pausing playback: \(error)")
                SentrySDK.capture(error: error) { scope in
                    scope.setContext(value: ["action": "pause"], key: "spotify_playback")
                    scope.setLevel(.warning)
                }
            }
        })
    }
    
    func skipToNext() {
        print("SkipToNext called. Playing next song from custom list.")
        isSkipping = true
        appRemote.playerAPI?.skip(toNext: { result, error in
            if let error = error {
                print("")
                SentrySDK.capture(error: error) { scope in
                    scope.setContext(value: ["action": "skip"], key: "spotify_playback")
                    scope.setLevel(.warning)
                }
            }
            self.isSkipping = false
        })
    }
    
    func rewind() {
        appRemote.playerAPI?.seek(toPosition: 0, callback: { result, error in
            if let error = error {
                print("Error rewinding track: \(error)")
                SentrySDK.capture(error: error) { scope in
                    scope.setContext(value: ["action": "rewind", "position": 0], key: "spotify_playback")
                    scope.setLevel(.warning)
                }
            }
        })
    }
    
    /// Queue a list of songs for playback
    /// - Parameter songs: Dictionary mapping song IDs to their BPM values
    func queue(songs: [String: Double]) {
        flushQueue(completion: {
            self.songMap = songs
            if !self.songMap.isEmpty {
                for song in self.songMap.keys.shuffled() {
                    self.enQueue(id: song)
                }
            } else {
                print("Queue initialized with empty song list.")
            }
        })
    }
    
    func enQueue(id: String) {
        let uri = "spotify:track:\(id)"
        appRemote.playerAPI?.enqueueTrackUri(uri, callback: { result, error in
            if let error = error {
                print("Error enqueuing track: \(error)")
                SentrySDK.capture(error: error) { scope in
                    scope.setContext(value: ["action": "enqueue_track", "uri": uri], key: "spotify_playback")
                    scope.setLevel(.warning)
                }
            }
        })
    }
    
    func flushQueue(completion: @escaping () -> Void) {
        let id = ""
        var skips = 0
        enQueue(id: id)
        while currentId != id && skips < 100 {
            if !isSkipping {
                skipToNext()
                skips += 1
            }
        }
        if currentId != id {
            print("Failed to flush queue, placeholder track not reached")
            SentrySDK.capture(message: "Failed to flush queue, placeholder track not reached" ) { scope in
                scope.setContext(value: ["action": "flush_queue"], key: "spotify_playback")
                scope.setLevel(.error)
            }
        } else {
            skipToNext()
        }
        
    }
    
    func turnOffRepeat() {
        self.appRemote.playerAPI?.setRepeatMode(.off, callback: { result, error in
            if let error = error {
                print("Error turning off repeat: \(error)")
                SentrySDK.capture(error: error) { scope in
                    scope.setContext(value: ["action": "set_repeat_off"], key: "spotify_playback")
                    scope.setLevel(.info)
                }
            }
        })
    }
    
    func disconnect() {
        if appRemote.isConnected {
            appRemote.disconnect()
        }
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
            
//            self.turnOffRepeat()
            
            // Check if we need to play next song
            // If song duration is available and we're near the end
//            if !self.isSkipping && !playerState.isPaused {
//                if playerState.playbackPosition < 500 && self.songMap[self.currentId] == nil { // Less than 500ms remaining
//                    print("Song ending, playing next song")
//                    self.skipToNext()
//                }
//            }
        }
    }
}
