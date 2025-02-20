//
//  SpotifyManager.swift
//  RunDJ
//
//  Created by Richard Cong on 2/16/25.
//

import UIKit
import SpotifyiOS

class SpotifyManager: NSObject, ObservableObject, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {
    
    static let shared = SpotifyManager()
    private let clientID = "6f69b8394f8d46fc87b274b54a3d9f1b"
    private let redirectURI = "run-dj://auth"
    private var accessToken: String?
    
    @Published var currentTrack: String? = "None"
    @Published var connectionState: ConnectionState = .disconnected
    
    enum ConnectionState: Equatable {
        case connected
        case disconnected
        case error(String)
        
        static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
            switch (lhs, rhs) {
            case (.connected, .connected):
                return true
            case (.disconnected, .disconnected):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    lazy var configuration: SPTConfiguration = {
        let config = SPTConfiguration(clientID: clientID, redirectURL: URL(string: redirectURI)!)
        // Add a default track URI to play if nothing else is specified
        config.playURI = ""
        return config
    }()
    
    lazy var appRemote: SPTAppRemote = {
        let remote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        remote.delegate = self
        return remote
    }()
    
    func handleAuthCallback(url: URL) {
        let parameters = appRemote.authorizationParameters(from: url)
        
        if let accessToken = parameters?[SPTAppRemoteAccessTokenKey] {
            self.accessToken = accessToken
            appRemote.connectionParameters.accessToken = accessToken
            connect()
        } else if let errorDescription = parameters?[SPTAppRemoteErrorDescriptionKey] {
            DispatchQueue.main.async {
                self.connectionState = .error("Auth Error: \(errorDescription)")
            }
        }
    }
    
    func authorizeAndPlay(playlistURI: String) {
        // If we have an access token, try to connect directly
        if let accessToken = self.accessToken {
            appRemote.connectionParameters.accessToken = accessToken
            connect()
            return
        }
        
        // Otherwise, start the authorization flow
        appRemote.authorizeAndPlayURI("spotify:playlist:\(playlistURI)") { [weak self] spotifyInstalled in
            guard let self = self else { return }
            
            if !spotifyInstalled {
                DispatchQueue.main.async {
                    self.connectionState = .error("Error initializing Spotify")
                }
            }
        }
    }
    
    func playPresetPlaylist(stepsPerMinute: Double) {
        let presetPlaylists = PresetPlaylists()
        let roundedStepsPerMinute = Int(round(stepsPerMinute / 5.0) * 5)
        if let playlistURI = presetPlaylists.playlists[roundedStepsPerMinute] {
            authorizeAndPlay(playlistURI: playlistURI)
            currentTrack = "\(roundedStepsPerMinute) BPM Playlist"
        }
    }
    
    func skipToNext() {
        print("skipToNext")
        print(appRemote.playerAPI)
        appRemote.playerAPI?.skip(toNext: { result, error in
            if let error = error {
                print("Error skipping to next track: \(error.localizedDescription)")
            }
        })
    }
    
    func connect() {
        guard !appRemote.isConnected else { return }
        
        // Ensure Spotify app is running
        if UIApplication.shared.canOpenURL(URL(string: "spotify:")!) {
            UIApplication.shared.open(URL(string: "spotify:")!, options: [:]) { [weak self] success in
                if success {
                    // Give Spotify a moment to fully launch
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.appRemote.connect()
                    }
                }
            }
        }
    }
    
    func disconnect() {
        if appRemote.isConnected {
            appRemote.disconnect()
        }
    }
    
    // MARK: - SPTAppRemoteDelegate
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("Connected to Spotify")
        DispatchQueue.main.async {
            self.connectionState = .connected
        }
        
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.connectionState = .error("Player subscription error: \(error.localizedDescription)")
                }
            }
        })
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        print("Failed to connect to Spotify: \(errorMessage)")
        DispatchQueue.main.async {
            self.connectionState = .error("Connection failed: \(errorMessage)")
        }
        
        // Attempt to reconnect if it was a temporary error
        if let error = error as NSError? {
            if error.domain == "com.spotify.app-remote.transport" && error.code == -2000 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.connect()
                }
            }
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("Disconnected from Spotify: \(error?.localizedDescription ?? "Unknown error")")
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
