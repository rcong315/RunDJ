//
//  RunDJService.swift
//  RunDJ
//
//  Created on 5/15/25.
//

import Foundation
import Combine

/// Service that manages interactions with the RunDJ API
class RunDJService: ObservableObject {
    static let shared = RunDJService()
    
    private let networkService: NetworkService
    
    // Cached songs for offline usage
    @Published var cachedSongs: [Double: [String: Double]] = [:]
    
    // MARK: - Initialization
    
    init(networkService: NetworkService = DefaultNetworkService()) {
        self.networkService = networkService
        print("RunDJService initialized")
    }
    
    // MARK: - Public Methods
    
    func register(accessToken: String, completion: @escaping (Bool) -> Void) {
        networkService.register(accessToken: accessToken, completion: completion)
    }
    
    /// Get a preset playlist based on steps per minute
    /// - Parameters:
    ///   - accessToken: Spotify access token
    ///   - stepsPerMinute: User's steps per minute
    ///   - completion: Completion handler with playlist URI
    func getPresetPlaylist(accessToken: String, stepsPerMinute: Double, completion: @escaping (String?) -> Void) {
        networkService.getPresetPlaylist(accessToken: accessToken, stepsPerMinute: stepsPerMinute, completion: completion)
    }
    
    /// Get songs matching a specific BPM
    /// - Parameters:
    ///   - accessToken: Spotify access token
    ///   - bpm: Target beats per minute
    ///   - sources: Spotify sources to search
    ///   - completion: Completion handler with song ID to BPM mapping
    func getSongsByBPM(accessToken: String, bpm: Double, sources: [String], completion: @escaping ([String: Double]) -> Void) {
        // Check if we have cached songs for this BPM
        if let cachedSongsForBPM = cachedSongs[bpm], !cachedSongsForBPM.isEmpty {
            print("Using \(cachedSongsForBPM.count) cached songs for BPM \(bpm)")
            completion(cachedSongsForBPM)
            return
        }
        
        // Fetch new songs
        networkService.getSongsByBPM(accessToken: accessToken, bpm: bpm, sources: sources) { [weak self] songs in
            // Cache the results if we got songs
            if !songs.isEmpty {
                self?.cachedSongs[bpm] = songs
            }
            completion(songs)
        }
    }
    
    /// Create a playlist with songs matching the given BPM
    /// - Parameters:
    ///   - accessToken: Spotify access token
    ///   - bpm: Target beats per minute
    ///   - sources: Spotify sources to search
    ///   - completion: Completion handler with playlist ID
    func createPlaylist(accessToken: String, bpm: Double, sources: [String], completion: @escaping (String?) -> Void) {
        networkService.createPlaylist(accessToken: accessToken, bpm: bpm, sources: sources, completion: completion)
    }
    
    /// Send feedback about a song
    /// - Parameters:
    ///   - accessToken: Spotify access token
    ///   - songId: ID of the song to provide feedback for
    ///   - feedback: Feedback type ("LIKE" or "DISLIKE")
    ///   - completion: Completion handler with success status
    func sendFeedback(accessToken: String, songId: String, feedback: String, completion: @escaping (Bool) -> Void = { _ in }) {
        networkService.sendFeedback(accessToken: accessToken, songId: songId, feedback: feedback, completion: completion)
    }
    
    /// Clear the song cache
    func clearCache() {
        cachedSongs.removeAll()
    }
}
