//
//  SpotifyManager2.swift
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
    private let serverURL = "https://rundjserver.onrender.com"
    
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
    
    func printSpotifyKeychain() {
        print("🔍 Current Spotify authentication data in keychain:")
        
        let accessToken = accessToken
        let tokenExpirationDate = tokenExpirationDate
        let refreshToken = refreshToken
        
        print("access token: \(accessToken ?? "")")
        print("refresh token: \(refreshToken ?? "")")
        
        let pstFormatter = DateFormatter()
        pstFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        pstFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let pstDateString = pstFormatter.string(from: tokenExpirationDate ?? Date())
        print("expires PST: \(pstDateString)")
    }
    
    // MARK: - Configuration
    
    lazy var configuration: SPTConfiguration = {
        let config = SPTConfiguration(clientID: clientID, redirectURL: URL(string: redirectURI)!)
        
        // Set server-side token swap and refresh URLs
        if let tokenSwapURL = URL(string: "\(serverURL)/api/spotify/auth/token"),
           let tokenRefreshURL = URL(string: "\(serverURL)/api/spotify/auth/refresh") {
            config.tokenSwapURL = tokenSwapURL
            config.tokenRefreshURL = tokenRefreshURL
            config.playURI = ""
        }
        
        return config
    }()
    
    lazy var sessionManager: SPTSessionManager = {
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        return manager
    }()
    
    lazy var appRemote: SPTAppRemote = {
        let remote = SPTAppRemote(configuration: configuration, logLevel: .debug)
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
            .userLibraryRead,
            .playlistReadPrivate,
            .streaming,
            .userReadEmail,
            .playlistModifyPublic,
            .playlistModifyPrivate,
            .userLibraryModify,
            .userTopRead
        ]
        
        sessionManager.initiateSession(with: scopes, options: .default, campaign: "Run DJ")
    }
    
    func handleURL(_ url: URL) {
        print("Handling Spotify URL: \(url)")
        let handled = sessionManager.application(UIApplication.shared, open: url)
        print("URL handled by session manager: \(handled)")
    }
    
    // MARK: - Playback Controls
    
    func play(uri: String) {
        print("Playing: \(uri)")
        appRemote.playerAPI?.play("spotify:playlist:\(uri)", callback: { result, error in
            if let error = error {
                print("Error playing playlist: \(error)")
            }
        })
        currentlyPlaying = "\(uri)"
    }
    
    func playPause() {
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
        appRemote.playerAPI?.skip(toNext: { result, error in
            if let error = error {
                print("Error skipping to next track: \(error)")
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
        
        // Save tokens to keychain
        refreshToken = session.refreshToken
        accessToken = session.accessToken
        tokenExpirationDate = session.expirationDate
        
        appRemote.connectionParameters.accessToken = session.accessToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.appRemote.connect()
        }
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("Session renewed")
        print("Access Token: \(session.accessToken)")
        print("Expiration Date: \(session.expirationDate)")
        
        // Save the renewed tokens
        accessToken = session.accessToken
        tokenExpirationDate = session.expirationDate
        
        appRemote.connectionParameters.accessToken = session.accessToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.appRemote.connect()
        }
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("Session failed with error: \(error)")
        print("Error domain: \(error._domain)")
        print("Error code: \(error._code)")
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
                DispatchQueue.main.async {
                    self?.connectionState = .error("Player subscription error: \(error.localizedDescription)")
                }
            } else {
                print("Successfully subscribed to player state")
            }
        })
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("Connection attempt failed with error: \(String(describing: error))")
        
        // Check if it's an authentication error
        if let error = error as NSError?,
           error.domain == "com.spotify.app-remote.wamp-client",
           error.code == -1001 {
            // Token might be invalid, try to reinitiate session
            print("Authentication failed, reinitiating session...")
            DispatchQueue.main.async {
                self.initiateSession()
            }
        }
        
        DispatchQueue.main.async {
            self.connectionState = .error("Connection failed: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        DispatchQueue.main.async {
            self.currentlyPlaying = playerState.track.name
        }
    }
}
