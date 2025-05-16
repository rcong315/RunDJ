//
//  SpotifyServiceProtocol.swift
//  RunDJ
//
//  Created on 5/15/25.
//

import Foundation
import Combine

/// Protocol defining the Spotify service operations needed by the app
protocol SpotifyServiceProtocol {
    var currentlyPlaying: String { get }
    var currentId: String { get }
    var currentBPM: Double { get }
    var connectionState: SpotifyManager.ConnectionState { get }
    var isPlaying: Bool { get }
    
    /// Initiates a Spotify authentication session
    func initiateSession(completion: (() -> Void)?)
    
    /// Retrieves the current access token
    func getAccessToken() -> String?
    
    /// Play a track with the given URI
    func play(uri: String)
    
    /// Resume playback of the current track
    func resume()
    
    /// Pause the currently playing track
    func pause()
    
    /// Skip to the next track
    func skipToNext()
    
    /// Rewind the current track to the beginning
    func rewind()
    
    /// Queue a list of songs for playback
    func queue(songs: [String: Double])
    
    /// Disconnect from Spotify
    func disconnect()
    
    /// Handle Spotify authentication redirect
    func handleURL(_ url: URL)
}

// Make SpotifyManager conform to SpotifyServiceProtocol
extension SpotifyManager: SpotifyServiceProtocol {}
