//
//  SpotifyManager.swift
//  RunDJ
//
//  Created by Richard Cong on 2/16/25.
//

import UIKit
import SpotifyiOS

class SpotifyManager: NSObject, ObservableObject, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate, SPTSessionManagerDelegate {
    
    static let shared = SpotifyManager()
    private let clientID = "6f69b8394f8d46fc87b274b54a3d9f1b"
    private let redirectURI = "run-dj://auth"
    
    private let keychainServiceName = "com.rundj.spotifyauth"
    private let refreshTokenKey = "spotify_refresh_token"
    private let accessTokenKey = "spotify_access_token"
    private let expirationDateKey = "spotify_expiration_date"
    
    @Published var currentlyPlaying: String? = "None"
    @Published var connectionState: ConnectionState = .disconnected
    
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
    
    // MARK: - Configuration
    
    lazy var configuration: SPTConfiguration = {
        let config = SPTConfiguration(clientID: clientID, redirectURL: URL(string: redirectURI)!)
        
        // Set server-side token swap and refresh URLs
        if let tokenSwapURL = URL(string: "https://9554-136-52-108-136.ngrok-free.app/api/spotify/auth/token"),
           let tokenRefreshURL = URL(string: "https://9554-136-52-108-136.ngrok-free.app/api/spotify/auth/refresh") {
            config.tokenSwapURL = tokenSwapURL
            config.tokenRefreshURL = tokenRefreshURL
            config.playURI = ""
        }
        
        return config
    }()
    
    lazy var sessionManager: SPTSessionManager = {
        let manager = SPTSessionManager(configuration: self.configuration, delegate: self)
        return manager
    }()
    
    lazy var appRemote: SPTAppRemote = {
        let remote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        remote.delegate = self
        return remote
    }()
    
    // MARK: - Initialization & App Lifecycle
    
    func isSpotifyInstalled() -> Bool {
        let spotifyURL = URL(string: "spotify:")!
        return UIApplication.shared.canOpenURL(spotifyURL)
    }
    
    private func isSpotifyAppReady() -> Bool {
        // Check if Spotify URL can be opened
        let spotifyURL = URL(string: "spotify:")!
        
        if UIApplication.shared.canOpenURL(spotifyURL) {
            // Additional check - try to open the app
            UIApplication.shared.open(spotifyURL, options: [:], completionHandler: nil)
            return true
        }
        return false
    }
    
    func applicationDidBecomeActive() {
        if connectionState == .disconnected && !appRemote.isConnected {
            initiateSession()
        }
    }
    
    // MARK: - Keychain Methods
    
    private func saveToKeychain(key: String, data: String) {
        // Delete any existing item
        deleteFromKeychain(key: key)
        
        guard let dataToStore = data.data(using: .utf8) else {
            print("🔑 Keychain ERROR: Failed to convert \(key) to Data")
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
            print("🔑 Keychain SUCCESS: Saved \(key) to Keychain")
        } else {
            print("🔑 Keychain ERROR: Failed saving \(key) to Keychain: \(status) - \(describeKeychainError(status))")
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
            print("🔑 Keychain SUCCESS: Loaded \(key) (length: \(string.count))")
            return string
        } else {
            if status == errSecItemNotFound {
                print("🔑 Keychain INFO: Item \(key) not found in Keychain")
            } else {
                print("🔑 Keychain ERROR: Failed loading \(key) from Keychain: \(status) - \(describeKeychainError(status))")
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
            print("🔑 Keychain ERROR: Failed deleting \(key) from Keychain: \(status) - \(describeKeychainError(status))")
        }
    }
    
    private func saveDateToKeychain(key: String, date: Date) {
        let timestamp = date.timeIntervalSince1970
        saveToKeychain(key: key, data: String(timestamp))
    }
    
    private func loadDateFromKeychain(key: String) -> Date? {
        guard let timestampString = loadFromKeychain(key: key),
              let timestamp = Double(timestampString) else {
            print("🔑 Keychain ERROR: Failed to parse date for \(key)")
            return nil
        }
        let date = Date(timeIntervalSince1970: timestamp)
        print("🔑 Keychain INFO: Loaded date \(date) for key \(key)")
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
    
    func clearSpotifyKeychain() {
        print("🧹 Clearing all Spotify authentication data from keychain")
        
        // Delete all stored token data
        deleteFromKeychain(key: refreshTokenKey)
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: expirationDateKey)
        
        // Reset the stored properties
        refreshToken = nil
        accessToken = nil
        tokenExpirationDate = nil
        
        // Reset app remote connection parameters
        appRemote.connectionParameters.accessToken = nil
        
        print("🧹 Spotify keychain data cleared successfully")
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
    
    func printTokenDebugInfo() {
        print("🔍 TOKEN DEBUG INFO 🔍")
        
        // Print access token info
        if let token = accessToken {
            print("📝 ACCESS TOKEN:")
            print("   Length: \(token.count)")
            print("   Value: \(token)")
            
            // Check if token appears valid (not checking with server, just format)
            let hasValidFormat = token.count > 20 && token.contains(".")
            print("   Appears valid format: \(hasValidFormat)")
            
            // Check if token is being set in connection parameters
            let connectionTokenMatch = appRemote.connectionParameters.accessToken == token
            print("   Matches connection parameter token: \(connectionTokenMatch)")
            
            if !connectionTokenMatch {
                print("   ⚠️ Connection parameter token differs from stored token!")
                if let connToken = appRemote.connectionParameters.accessToken {
                    print("   Connection token first 10: \(connToken.prefix(10))...")
                } else {
                    print("   Connection parameter token is nil")
                }
            }
        } else {
            print("❌ ACCESS TOKEN: Not found in keychain")
        }
        
        // Print refresh token info
        if let refreshTkn = refreshToken {
            print("🔄 REFRESH TOKEN:")
            print("   Length: \(refreshTkn.count)")
            print("   Value: \(refreshTkn)")
        } else {
            print("❌ REFRESH TOKEN: Not found in keychain")
        }
        
        // Print expiration info
        if let expDate = tokenExpirationDate {
            print("⏱️ EXPIRATION DATE: \(expDate)")
            let timeRemaining = expDate.timeIntervalSinceNow
            print("   Time remaining: \(Int(timeRemaining)) seconds (\(Int(timeRemaining / 60)) minutes)")
            print("   Is expired: \(timeRemaining <= 0)")
            print("   Is valid (with 5-min buffer): \(timeRemaining > 300)")
        } else {
            print("❌ EXPIRATION DATE: Not found in keychain")
        }
        
        print("🔍 END TOKEN DEBUG INFO 🔍")
    }
    
    // MARK: - Authentication Flow
    
    func initiateSession() {
        print("🎵 Initiating Spotify session...")
        
        validateConnectionParameters()
        
        // First check if Spotify is installed
            guard isSpotifyInstalled() else {
                print("❌ Spotify app is not installed")
                DispatchQueue.main.async {
                    self.connectionState = .error("Spotify app is not installed. Please install Spotify from the App Store.")
                }
                return
            }
            
            // Ensure Spotify app is ready
            if !isSpotifyAppReady() {
                print("⚠️ Spotify app may not be running")
                DispatchQueue.main.async {
                    self.connectionState = .error("Please ensure Spotify app is open and running")
                }
                return
            }
            
            // Disconnect if already connected
            if appRemote.isConnected {
                print("🔄 Disconnecting existing connection before reconnecting")
                disconnect()
            }
        
        // Check if we have a valid access token
        if isTokenValid {
            print("✅ Using existing valid token from keychain")
            connectToSpotify()
            return
        }
        
        // If tokens exist but may be invalid, clear them and start fresh
        if refreshToken != nil || accessToken != nil {
            print("🔄 Tokens exist but may be invalid, clearing and starting fresh")
            clearSpotifyKeychain()
        }
        
        // No valid tokens, need to authorize from scratch
        print("🔑 No valid tokens found, initiating new authorization")
        authorizeSpotify()
    }
    
    private func authorizeSpotify() {
        // Define the scopes needed for your app
        let scopes: SPTScope = [
            .streaming,
            .appRemoteControl,
            .playlistReadPrivate,
            .playlistModifyPublic,
            .playlistModifyPrivate,
            .userReadEmail,
            .userTopRead,
            .userFollowRead,
            .userLibraryRead,
            .userLibraryModify
        ]
        
        // Clear existing token in case of previous failed attempts
        accessToken = nil
        
        // Use only the server-side authentication approach
        sessionManager.initiateSession(with: scopes, options: .default, campaign: "RunDJ")
    }
    
    private func connectToSpotify() {
        guard let token = accessToken else {
            print("❌ No access token available for connection")
            DispatchQueue.main.async {
                self.connectionState = .error("Authentication error: No access token available")
            }
            return
        }
        
        print("🔌 Connecting to Spotify with token: \(String(token.prefix(5)))...")
        appRemote.connectionParameters.accessToken = token
        
        printTokenDebugInfo()
        
        // Check if we're coming from an authentication flow
        let isComingFromAuth = tokenExpirationDate != nil &&
        tokenExpirationDate!.timeIntervalSinceNow > 3500 // New token (within last minute)
        
        if isComingFromAuth {
            print("🔄 Coming from fresh authentication, waiting before connection...")
            // Give Spotify app more time to be ready for connections
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                print("🔄 Now attempting connection after waiting")
                self.appRemote.connect()
            }
        } else {
            // Normal flow - use retry mechanism
            if !appRemote.isConnected {
                print("🔄 Attempting to connect to Spotify...")
                appRemote.connect()
            }
        }
    }
    
    func handleURL(_ url: URL) {
        print("🔗 Handling Spotify URL callback: \(url)")
        let handled = sessionManager.application(UIApplication.shared, open: url)
        print("URL handled by session manager: \(handled)")
    }
    
    // MARK: - Playback Controls
    
    func play(uri: String) {
        guard appRemote.isConnected else {
            print("❌ Not connected to Spotify")
            reconnectIfNeeded { success in
                if success {
                    self.play(uri: uri)
                }
            }
            return
        }
        
        print("▶️ Playing: \(uri)")
        appRemote.playerAPI?.play("spotify:playlist:\(uri)", callback: { result, error in
            if let error = error {
                print("Error playing playlist: \(error)")
            }
        })
        currentlyPlaying = "\(uri)"
    }
    
    func playPause() {
        guard appRemote.isConnected else {
            print("❌ Not connected to Spotify")
            reconnectIfNeeded()
            return
        }
        
        appRemote.playerAPI?.getPlayerState() { [weak self] result, error in
            guard let self = self, let state = result as? SPTAppRemotePlayerState else {
                print("Error getting player state: \(error ?? NSError())")
                return
            }
            
            if state.isPaused {
                self.appRemote.playerAPI?.resume({ result, error in
                    if let error = error {
                        print("Error resuming playback: \(error)")
                    }
                })
            } else {
                self.appRemote.playerAPI?.pause({ result, error in
                    if let error = error {
                        print("Error pausing playback: \(error)")
                    }
                })
            }
        }
    }
    
    func skipToNext() {
        guard appRemote.isConnected else {
            print("❌ Not connected to Spotify")
            reconnectIfNeeded()
            return
        }
        
        appRemote.playerAPI?.skip(toNext: { result, error in
            if let error = error {
                print("Error skipping to next track: \(error)")
            }
        })
    }
    
    func disconnect() {
        if appRemote.isConnected {
            print("🔌 Disconnecting from Spotify")
            appRemote.disconnect()
        }
    }
    
    private func reconnectIfNeeded(completion: ((Bool) -> Void)? = nil) {
        print("🔄 Attempting to reconnect to Spotify...")
        
        if isTokenValid {
            connectToSpotify()
            
            // Check connection after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                let success = self.appRemote.isConnected
                completion?(success)
                
                if !success {
                    print("❌ Reconnection attempt failed")
                    DispatchQueue.main.async {
                        self.connectionState = .error("Failed to reconnect to Spotify")
                    }
                }
            }
        } else {
            // No valid token, need to re-authenticate
            initiateSession()
            completion?(false)
        }
    }
    
    func validateConnectionParameters() {
        print("🔍 VALIDATING CONNECTION PARAMETERS 🔍")
        
        // Check if Spotify is installed
        let spotifyInstalled = isSpotifyInstalled()
        print("📱 Spotify app installed: \(spotifyInstalled)")
        
        // Check if the redirect URI is configured correctly
        print("🔗 Redirect URI: \(redirectURI)")
        print("   Valid format: \(redirectURI.contains("://"))")
        
        // Check token swap/refresh URLs
        if let tokenSwapURL = configuration.tokenSwapURL {
            print("💱 Token swap URL: \(tokenSwapURL)")
            // Check if the URL is reachable (simple check, not actual network test)
            let isHTTPS = tokenSwapURL.scheme == "https"
            print("   Uses HTTPS: \(isHTTPS)")
        } else {
            print("❌ Token swap URL not configured")
        }
        
        if let tokenRefreshURL = configuration.tokenRefreshURL {
            print("🔄 Token refresh URL: \(tokenRefreshURL)")
            let isHTTPS = tokenRefreshURL.scheme == "https"
            print("   Uses HTTPS: \(isHTTPS)")
        } else {
            print("❌ Token refresh URL not configured")
        }
        
        // Check if ngrok URLs are active (they expire and change)
        if let tokenSwapURL = configuration.tokenSwapURL?.absoluteString,
           tokenSwapURL.contains("ngrok") {
            print("⚠️ Using ngrok URL for token swap - these expire, make sure it's active")
        }
        
        // Check connection parameters
        print("🎮 App Remote Connection Parameters:")
        print("   isConnected: \(appRemote.isConnected)")
        if let token = appRemote.connectionParameters.accessToken {
            print("   Access Token: \(token.prefix(10))...")
            print("   Token Length: \(token.count)")
        } else {
            print("   ❌ No access token in connection parameters")
        }
        
        print("🔍 END CONNECTION VALIDATION 🔍")
    }
    
    // MARK: - SPTSessionManagerDelegate
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("✅ Session initiated successfully")
        print("Refresh Token: \(session.refreshToken)")
        print("Access Token: \(String(session.accessToken.prefix(5)))...")
        print("Expiration Date: \(session.expirationDate)")
        
        // Save tokens to keychain
        refreshToken = session.refreshToken
        accessToken = session.accessToken
        tokenExpirationDate = session.expirationDate
        
        // Connect to Spotify with the new token
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.connectToSpotify()
        }
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("🔄 Session renewed successfully")
        print("Access Token: \(String(session.accessToken.prefix(5)))...")
        print("Expiration Date: \(session.expirationDate)")
        
        // Save the renewed tokens
        accessToken = session.accessToken
        tokenExpirationDate = session.expirationDate
        
        // Connect with the new token if not already connected
        if !appRemote.isConnected {
            connectToSpotify()
        }
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("❌ Session failed with error: \(error)")
        print("Error domain: \(error._domain)")
        print("Error code: \(error._code)")
        
        // Check if this is an authentication error
//        let nsError = error as NSError
//        if nsError.domain == "com.spotify.sdk.login" ||
//            nsError._domain == "com.spotify.sdk.login" ||
//            (nsError.domain == "com.spotify.sdk.session-manager" && nsError.code == 7) {
//            
//            print("Authentication error detected - clearing keychain data")
//            clearSpotifyKeychain()
//            
//            // Try to authenticate again from scratch after a short delay
//            //            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            //                self.authorizeSpotify()
//            //            }
//        }
        
        DispatchQueue.main.async {
            self.connectionState = .error("Authentication failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - SPTAppRemoteDelegate
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("✅ Connected to Spotify")
        DispatchQueue.main.async {
            self.connectionState = .connected
        }
        
        print("Setting up player API")
        appRemote.playerAPI?.delegate = self
        
        // Subscribe to player state updates
        appRemote.playerAPI?.subscribe(toPlayerState: { result, error in
            if let error = error {
                print("⚠️ Player subscription error: \(error)")
            } else {
                print("✅ Successfully subscribed to player state")
            }
        })
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("❌ Connection attempt failed with error: \(String(describing: error))")
        
        print("Token state at connection failure:")
        printTokenDebugInfo()
        
        // Extract the underlying error for better diagnosis
        var errorMessage = "Connection failed: \(error?.localizedDescription ?? "Unknown error")"
        var shouldRetryAuth = false
        
        if let err = error as NSError? {
            if err.domain == "com.spotify.app-remote" {
                let underlyingError = err.userInfo["NSUnderlyingError"] as? NSError
                if let transportError = underlyingError?.userInfo["NSUnderlyingError"] as? NSError {
                    print("🔍 Transport error: \(transportError.domain) Code: \(transportError.code)")
                    
                    // Connection refused - Spotify app not ready
                    if transportError.domain == "NSPOSIXErrorDomain" && transportError.code == 61 {
                        print("⚠️ Connection refused - is Spotify app running?")
                        errorMessage = "Please ensure Spotify app is open and ready"
                        
                        // Try to launch Spotify app
                        let spotifyURL = URL(string: "spotify:")!
                        UIApplication.shared.open(spotifyURL, options: [:]) { success in
                            if success {
                                print("🚀 Launched Spotify app, will retry connection in 5 seconds")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                    self.connectToSpotify()
                                }
                            }
                        }
                    }
                }
                
                // Check for authentication errors
                if err.code == -1003 { // Invalid access token
                    print("⚠️ Authentication error detected")
                    errorMessage = "Authentication error - will try to reauthorize"
                    shouldRetryAuth = true
                }
            }
        }
        
        DispatchQueue.main.async {
            self.connectionState = .error(errorMessage)
        }
        
        if shouldRetryAuth {
            // Clear tokens and re-authenticate
            clearSpotifyKeychain()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.authorizeSpotify()
            }
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("🔌 Disconnected from Spotify: \(String(describing: error))")
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
    }
    
    // MARK: - SPTAppRemotePlayerStateDelegate
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        let trackName = playerState.track.name
        print("🎵 Now playing: \(trackName)")
        
        DispatchQueue.main.async {
            self.currentlyPlaying = trackName
        }
    }
}
