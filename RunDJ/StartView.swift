//
//  StartView.swift
//  RunDJ
//
//  Created by Richard Cong on 3/20/25.
//

import SwiftUI

struct StartView: View {
    @StateObject private var pedometerManager = PedometerManager()
    
    @State private var navigateToContentView = false
    
    // The current gradient from the welcome page
    private var gradientColors = Style().gradientColors
    private var foregroundColor = Style().foregroundColor
    
    // State for the target BPM setting
    @State private var targetBPM: Int = 160
    
    // Add state to track which option was selected
    @State private var useCustomBPM: Bool = false
    
    // State for animation
    @State private var waveOffset: CGFloat = 0
    @State private var isAnimating = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient matching the welcome page
                LinearGradient(colors: gradientColors,
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                .ignoresSafeArea()
                
                // Sound wave pattern overlay
                GeometryReader { geo in
                    let width = geo.size.width
                    let height = geo.size.height
                    
                    ZStack {
                        // Horizontal sound waves
                        ForEach(0..<3) { i in
                            SoundWave(amplitude: 20 + CGFloat(i * 5), frequency: 0.02, phase: waveOffset)
                                .stroke(foregroundColor.opacity(0.15), lineWidth: 2)
                                .frame(width: width, height: 80)
                                .offset(y: height / 4 + CGFloat(i * 40))
                        }
                    }
                    .onAppear {
                        withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                            waveOffset += 2 * .pi
                        }
                    }
                }
                
                ScrollView {
                    VStack {
                        // Header
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20))
                                    .foregroundColor(foregroundColor)
                                    .padding(.leading, 20)
                            }
                            
                            Spacer()
                            
                            Text("Start")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(foregroundColor)
                            
                            Spacer()
                            
                            Button(action: {
                                // Settings action
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 20))
                                    .foregroundColor(foregroundColor)
                                    .padding(.trailing, 20)
                            }
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // SECTION 1: Current Steps Per Minute Display
                        VStack(spacing: 15) {
                            Text("OPTION 1: MATCH MY CURRENT PACE")
                                .font(.system(size: 16, weight: .semibold))
                                .tracking(1)
                                .foregroundColor(foregroundColor.opacity(0.9))
                            
                            ZStack {
                                // Background Circle
                                Circle()
                                    .fill(foregroundColor.opacity(0.15))
                                    .frame(width: 180, height: 180)
                                
                                // Pulsating Circle
                                Circle()
                                    .stroke(foregroundColor, lineWidth: isAnimating ? 1 : 3)
                                    .frame(width: 190, height: 190)
                                    .onAppear {
                                        withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                            isAnimating.toggle()
                                        }
                                    }
                                
                                VStack(spacing: 5) {
                                    Text("\(pedometerManager.stepsPerMinute)")
                                        .font(.system(size: 62, weight: .bold))
                                        .foregroundColor(foregroundColor)
                                    
                                    Text("STEPS/MIN")
                                        .font(.system(size: 14, weight: .medium))
                                        .tracking(1)
                                        .foregroundColor(foregroundColor.opacity(0.7))
                                }
                            }
                            .padding(.vertical, 20)
                            
                            // Start button for current steps section
                            Button(action: {
                                useCustomBPM = false
                                navigateToContentView = true
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 16))
                                    
                                    Text("START WITH CURRENT PACE")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(gradientColors[1])
                                .frame(width: 260, height: 55)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(foregroundColor)
                                )
                            }
                        }
                        //                    .padding(.bottom, 30)
                        
                        // Section Divider
                        HStack {
                            Rectangle()
                                .fill(foregroundColor.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("OR")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(foregroundColor)
                                .padding(.horizontal, 15)
                            
                            Rectangle()
                                .fill(foregroundColor.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 20)
                        
                        // SECTION 2: BPM Setting Section
                        VStack(spacing: 20) {
                            Text("OPTION 2: SET CUSTOM BPM")
                                .font(.system(size: 16, weight: .semibold))
                                .tracking(1)
                                .foregroundColor(foregroundColor.opacity(0.9))
                                .padding(.bottom, 10)
                            
                            // BPM Selector
                            HStack(spacing: 20) {
                                Button(action: {
                                    if targetBPM > 130 {
                                        targetBPM -= 5
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 34))
                                        .foregroundColor(foregroundColor)
                                }
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(foregroundColor.opacity(0.2))
                                        .frame(width: 120, height: 70)
                                    
                                    Text("\(targetBPM)")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(foregroundColor)
                                }
                                
                                Button(action: {
                                    if targetBPM < 190 {
                                        targetBPM += 5
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 34))
                                        .foregroundColor(foregroundColor)
                                }
                            }
                            
                            // BPM Range indicator
                            Text("Range: 130-190 BPM")
                                .font(.system(size: 14))
                                .foregroundColor(foregroundColor.opacity(0.7))
                                .padding(.top, 5)
                                .padding(.bottom, 20)
                            
                            // Action Button for custom BPM
                            Button(action: {
                                useCustomBPM = true
                                navigateToContentView = true
                            }) {
                                HStack {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 16))
                                    
                                    Text("START WITH CUSTOM BPM")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(gradientColors[1])
                                .frame(width: 260, height: 55)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(foregroundColor)
                                )
                            }
                        }
                        .padding(.bottom, 40)
                        
                        // Footer
                        HStack(spacing: 2) {
                            Text("PERFECT BEATS FOR PERFECT RUNS")
                                .font(.system(size: 10, weight: .medium))
                                .tracking(1)
                                .foregroundColor(foregroundColor.opacity(0.7))
                        }
                        .padding(.bottom, 15)
                    }
                    .padding(.vertical, 10)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToContentView) {
            // Pass both values to RunningView
            RunningView(targetBPM: targetBPM, useCustomBPM: useCustomBPM)
        }
    }
}

struct BPMStat: View {
    let icon: String
    let value: String
    let label: String
    let foregroundColor = Style().foregroundColor
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(foregroundColor)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(foregroundColor)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(foregroundColor.opacity(0.7))
        }
        .frame(width: 70)
    }
}

#Preview {
    StartView()
}
