//
//  BPMView.swift
//  RunDJ
//
//  Created on 5/15/25.
//

import SwiftUI

/// View for showing BPM options and starting a run
struct BPMView: View {
    // MARK: - Dependencies
    
    @StateObject private var pedometerManager = PedometerManager.shared
    @StateObject private var spotifyManager = SpotifyManager.shared
    @StateObject private var runDJService = RunDJService.shared
    
    // MARK: - State
    
    @State private var bpmValue = 150
    @State private var bpmText = "150"
    @State private var showingHelp = false
            
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
            
            Spacer()
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
            
            NavigationLink(destination: RunningView(bpm: pedometerManager.stepsPerMinute).environmentObject(SettingsManager.shared)) {
                Text("Start")
                    .padding()
                    .frame(minWidth: 150)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
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
            
            Text("Set Your Target BPM")
                .font(.title)
                .padding(.top)
            
            HStack {
                Button(action: {
                    print("Minus button pressed")
                    if bpmValue > 100 {
                        bpmValue -= 1
                        bpmText = "\(bpmValue)"
                    }
                }) {
                    Image(systemName: "minus.circle")
                        .font(.title)
                        .foregroundColor(.green)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                
                TextField("BPM", text: $bpmText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onChange(of: bpmText) { oldValue, newValue in
                        if let newValue = Int(newValue) {
                            bpmValue = max(100, min(200, newValue))
                            if newValue != bpmValue {
                                bpmText = "\(bpmValue)"  // Update text to match constrained value
                            }
                        }
                    }
                
                Button(action: {
                    print("Plus button pressed")
                    if bpmValue < 200 {
                        bpmValue += 1
                        bpmText = "\(bpmValue)"
                    }
                }) {
                    Image(systemName: "plus.circle")
                        .font(.title)
                        .foregroundColor(.green)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
            .padding()
            
            NavigationLink(destination: RunningView(bpm: Double(bpmValue)).environmentObject(SettingsManager.shared)) {
                Text("Start")
                    .padding()
                    .frame(minWidth: 150)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            Spacer()
            }
            .padding()
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingHelp = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .padding()
                }
            }
        }
    }
}
    
#Preview {
    NavigationStack {
        BPMView()
    }
}
