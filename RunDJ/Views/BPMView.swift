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
            ZStack {
                Color.rundjBackground
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text("RunDJ")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.rundjMusicGreen)
                            
                            Text("Match Music to Your Steps")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.rundjTextPrimary)
                        }
                        .padding(.top, 20)
                        
                        // Auto BPM Section
                        VStack(spacing: 16) {
                            Text("Start running and RunDJ will measure your pace")
                                .font(.system(size: 14))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.rundjTextSecondary)
                                .padding(.horizontal)
                            
                            // Steps Display
                            VStack(spacing: 8) {
                                Text("\(pedometerManager.stepsPerMinute.formatted(.number.precision(.fractionLength(0))))")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.rundjMusicGreen)
                                
                                Text("Steps Per Minute")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.rundjTextSecondary)
                            }
                            .frame(width: 180, height: 100)
                            .background(Color.rundjCardBackground)
                            .cornerRadius(16)
                            
                            Button(action: {
                                let steps = pedometerManager.stepsPerMinute
                                if steps >= 100 && steps <= 200 {
                                    navigateToRunning = true
                                } else {
                                    showingStepsAlert = true
                                }
                            }) {
                                Text("Start with Auto BPM")
                            }
                            .buttonStyle(RundjPrimaryButtonStyle(isMusic: true))
                            .padding(.horizontal, 40)
                        }
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color.rundjTextTertiary.opacity(0.3))
                            
                            Text("OR")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.rundjTextTertiary)
                                .padding(.horizontal, 12)
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color.rundjTextTertiary.opacity(0.3))
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        
                        // Manual BPM Section
                        VStack(spacing: 16) {
                            Text("Set Your Target BPM")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.rundjTextPrimary)
                            
                            // BPM Control
                            HStack(spacing: 16) {
                                Button(action: {
                                    bpmValue = max(100, bpmValue - 5)
                                    bpmText = "\(bpmValue)"
                                }) {
                                    Image(systemName: "minus")
                                        .font(.system(size: 20, weight: .medium))
                                }
                                .buttonStyle(RundjIconButtonStyle(size: 36, isMusic: true))
                                
                                VStack(spacing: 4) {
                                    TextField("BPM", text: $bpmText)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.rundjMusicGreen)
                                        .frame(width: 100)
                                    
                                    Text("BPM")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.rundjTextSecondary)
                                }
                                
                                Button(action: {
                                    bpmValue = min(200, bpmValue + 5)
                                    bpmText = "\(bpmValue)"
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .medium))
                                }
                                .buttonStyle(RundjIconButtonStyle(size: 36, isMusic: true))
                            }
                            
                            // Quick adjust buttons
                            HStack(spacing: 12) {
                                Button("-1") {
                                    bpmValue = max(100, bpmValue - 1)
                                    bpmText = "\(bpmValue)"
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.rundjTextSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.rundjCardBackground)
                                .cornerRadius(8)
                                
                                Button("+1") {
                                    bpmValue = min(200, bpmValue + 1)
                                    bpmText = "\(bpmValue)"
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.rundjTextSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.rundjCardBackground)
                                .cornerRadius(8)
                            }
                            
                            NavigationLink(destination: RunningView(bpm: Double(bpmValue)).environmentObject(SettingsManager.shared)) {
                                Text("Start with Manual BPM")
                            }
                            .buttonStyle(RundjPrimaryButtonStyle())
                            .padding(.horizontal, 40)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationDestination(isPresented: $navigateToRunning) {
                RunningView(bpm: pedometerManager.stepsPerMinute).environmentObject(SettingsManager.shared)
            }
            .sheet(isPresented: $showingHelp) {
                HelpView(context: .bpmView)
            }
            .alert("Steps Out of Range", isPresented: $showingStepsAlert) {
                Button("OK") { }
            } message: {
                Text("Your steps per minute (\(Int(pedometerManager.stepsPerMinute))) is outside the valid range of 100-200. Please adjust your pace and try again.")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingHelp = true
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.rundjAccent)
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        if let value = Int(bpmText) {
                            bpmValue = max(100, min(200, value))
                        }
                        bpmText = "\(bpmValue)"
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .foregroundColor(.rundjMusicGreen)
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
