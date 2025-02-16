//
//  ContentView.swift
//  RunDJ
//
//  Created by Richard Cong on 2/8/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var pedometerManager = PedometerManager()
//    @StateObject private var spotifyManager = SpotifyManager()*/
    
    var body: some View {
        VStack {
//            Text("Current Track: \(spotifyManager.currentTrack ?? "None")")
            Text("Steps Per Minute: \(pedometerManager.stepsPerMinute)")
        }
    }
}

#Preview {
    ContentView()
}
