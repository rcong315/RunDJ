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
                        print("-5 button pressed")
                        bpmValue = max(100, bpmValue - 5)
                        bpmText = "\(bpmValue)"
                    }) {
                        Text("-5")
                            .padding(.horizontal, 10)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        print("-1 button pressed")
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
                        print("+1 button pressed")
                        bpmValue = min(200, bpmValue + 1)
                        bpmText = "\(bpmValue)"
                    }) {
                        Text("+1")
                            .padding(.horizontal, 10)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        print("+5 button pressed")
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
