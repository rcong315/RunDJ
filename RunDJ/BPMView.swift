//
//  BPMView.swift
//  RunDJ
//
//  Created on 4/29/25.
//

import SwiftUI

struct BPMView: View {
    @StateObject private var pedometerManager = PedometerManager.shared
    @StateObject private var spotifyManager = SpotifyManager.shared
    @StateObject private var runDJService = RunDJService.shared
    
    @State private var bpmValue: Int = 150
    @State private var bpmText: String = "150"
    
    @State private var showingHelp = false
    
    @State private var songs: [String] = []
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    
    var sources: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: {
                    showingHelp = true
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .padding()
            }
            
            Text("Set Your Target BPM")
                .font(.title)
                .padding(.top)
            
            HStack {
                Button(action: {
                    if bpmValue > 100 {
                        bpmValue -= 1
                        bpmText = "\(bpmValue)"
                    }
                }) {
                    Image(systemName: "minus.circle")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                
                TextField("BPM", text: $bpmText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onSubmit {
                        if let newValue = Int(bpmText) {
                            bpmValue = max(100, min(200, newValue))
                            bpmText = "\(bpmValue)"  // Update text to match constrained value
                        } else {
                            bpmText = "\(bpmValue)"  // Reset to previous valid value
                        }
                    }
                
                Button(action: {
                    if bpmValue < 200 {
                        bpmValue += 1
                        bpmText = "\(bpmValue)"
                    }
                }) {
                    Image(systemName: "plus.circle")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            
            Button(action: {
                isLoading = true
                runDJService.getSongsByBPM(
                    accessToken: spotifyManager.getAccessToken()!,
                    bpm: Double(bpmValue),
                    sources: sources
                ) { fetchedSongs in
                    isLoading = false
                    if !fetchedSongs.isEmpty {
                        songs = fetchedSongs
                        // The NavigationLink below will handle this
                    } else {
                        showError = true
                    }
                }
            }) {
                Text("Fetch Songs")
                    .padding()
                    .frame(minWidth: 200)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isLoading)
            
            // Only show this navigation link when we have songs
            if !songs.isEmpty {
                NavigationLink(destination: RunningView(bpm: Double(bpmValue), songs: songs)) {
                    Text("Start Running with Songs")
                        .padding()
                        .frame(minWidth: 200)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray)
                
                Text("OR")
                    .font(.title)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray)
            }
            .padding()
            
            Text("Match Music to Your Steps")
                .font(.title)
            
            Text("Start running and give RunDJ a few seconds to measure your steps per minute.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            Text("\(pedometerManager.stepsPerMinute)\nSteps Per Minute")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: RunningView(bpm: pedometerManager.stepsPerMinute, songs: [])) {
                Text("Start")
                    .padding()
                    .frame(minWidth: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text("Could not find songs matching your criteria"),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
    }
}

#Preview {
    NavigationStack {
        BPMView(sources: [])
    }
}
