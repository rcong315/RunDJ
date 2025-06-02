//
//  BPMView.swift
//  RunDJ
//
//  Created on 5/15/25.
//

import SwiftUI

/// View for showing BPM options and starting a run
struct BPMView: View {
    @StateObject private var pedometerManager = PedometerManager.shared
    @StateObject private var spotifyManager = SpotifyManager.shared
    @StateObject private var runDJService = RunDJService.shared
        
    @State private var bpmValue = 150
    @State private var bpmText = "150"
    @State private var showingHelp = false
    @State private var showingStepsAlert = false
    @State private var navigateToRunning = false
    
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
                
                Text("\(pedometerManager.stepsPerMinute.formatted(.number.precision(.fractionLength(1))))\nSteps Per Minute")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding()
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    let steps = pedometerManager.stepsPerMinute
                    if steps >= 100 && steps <= 200 {
                        navigateToRunning = true
                    } else {
                        showingStepsAlert = true
                    }
                }) {
                    Text("Start")
                        .padding()
                        .frame(minWidth: 150)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .navigationDestination(isPresented: $navigateToRunning) {
                    RunningView(bpm: pedometerManager.stepsPerMinute).environmentObject(SettingsManager.shared)
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
                        bpmValue = max(100, bpmValue - 5)
                        bpmText = "\(bpmValue)"
                    }) {
                        Text("-5")
                            .padding(.horizontal, 10)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        bpmValue = max(100, bpmValue - 1)
                        bpmText = "\(bpmValue)"
                    }) {
                        Text("-1")
                            .padding(.horizontal, 10)
                            .foregroundColor(.green)
                    }
                    
                    TextField("BPM", text: $bpmText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 80)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Button(action: {
                        bpmValue = min(200, bpmValue + 1)
                        bpmText = "\(bpmValue)"
                    }) {
                        Text("+1")
                            .padding(.horizontal, 10)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        bpmValue = min(200, bpmValue + 5)
                        bpmText = "\(bpmValue)"
                    }) {
                        Text("+5")
                            .padding(.horizontal, 10)
                            .foregroundColor(.green)
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
                HelpView(context: .bpmView)
            }
            .alert("Steps Out of Range", isPresented: $showingStepsAlert) {
                Button("OK") { }
            } message: {
                Text("Your steps per minute (\(pedometerManager.stepsPerMinute)) is outside the valid range of 100-200. Please adjust your pace and try again.")
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
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Done") {
                        if let value = Int(bpmText) {
                            bpmValue = max(100, min(200, value))
                        }
                        bpmText = "\(bpmValue)"
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
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
