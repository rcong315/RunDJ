//
//  Song.swift
//  RunDJ
//
//  Created on 5/15/25.
//

import Foundation

/// Model representing a song from Spotify with its BPM information
struct Song: Identifiable, Hashable {
    let id: String
    let name: String
    let artistName: String
    let bpm: Double
    let uri: String
    
    var spotifyURI: String {
        return "spotify:track:\(id)"
    }
    
    init(id: String, name: String, artistName: String, bpm: Double) {
        self.id = id
        self.name = name
        self.artistName = artistName
        self.bpm = bpm
        self.uri = "spotify:track:\(id)"
    }
    
    // For cases where we only have the ID and BPM
    init(id: String, bpm: Double) {
        self.id = id
        self.name = ""
        self.artistName = ""
        self.bpm = bpm
        self.uri = "spotify:track:\(id)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.id == rhs.id
    }
}
