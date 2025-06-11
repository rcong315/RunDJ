//
//  SpotifyManager2.swift
//  RunDJ
//
//  Created by Richard Cong on 5/4/25.
//

import UIKit
import SpotifyiOS

class SpotifyManager2: UIViewController, SPTSessionManagerDelegate {
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("Session initiated")
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: any Error) {
        print("Session failed: \(error)")
    }
    
    static let shared = SpotifyManager2()
    
    private let clientID = "6f69b8394f8d46fc87b274b54a3d9f1b"
    private let redirectURI = "rundj://callback"
    private let serverURL = "https://rundjserver.onrender.com"
    
    let configuration = SPTConfiguration(
        clientID: "6f69b8394f8d46fc87b274b54a3d9f1b",
        redirectURL: URL(string: "run-dj://auth")!
    )
    
    // Session manager for authentication
    lazy var sessionManager: SPTSessionManager = {
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        return manager
    }()
    
    // Player instance
    var player: SPTAppRemotePlayerAPI?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup player and authentication
    }
    
    func setupPlayer(accessToken: String) {
        // Initialize player with token
        // Handle playback controls
    }
    
    func play(trackURI: String) {
        // Start playback of a specific track
    }
}
