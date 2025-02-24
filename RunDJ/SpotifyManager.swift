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
    private var refreshToken: String?
    private var accessToken: String?
    
    @Published var currentTrack: String? = "None"
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
    
    lazy var configuration: SPTConfiguration = {
        let config = SPTConfiguration(clientID: clientID, redirectURL: URL(string: redirectURI)!)
        config.playURI = ""
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
        
        self.accessToken = nil
        
        sessionManager.initiateSession(with: scopes, options: .default, campaign: "Run DJ")
    }
    
    func handleURL(_ url: URL) {
        print("Handling Spotify URL: \(url)")
        let handled = sessionManager.application(UIApplication.shared, open: url)
        print("URL handled by session manager: \(handled)")
        
        // For debugging
        if let code = url.queryParameters?["code"] {
            print("Auth code received: \(code)")
        }
    }
    
    func play(uri: String) {
        guard appRemote.isConnected else {
            print("Not connected to Spotify")
            return
        }
        print("Playing: \(uri)")
        appRemote.playerAPI?.play("spotify:playlist:\(uri)", callback: { result, error in
            if let error = error {
                print("Error playing playlist: \(error)")
            }
        })
        currentTrack = "\(uri)"
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
        print("Access Token: \(session.accessToken)")
        print("Expiration Date: \(session.expirationDate)")
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
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        appRemote.connectionParameters.accessToken = session.accessToken
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
            self.currentTrack = playerState.track.name
        }
    }
}
