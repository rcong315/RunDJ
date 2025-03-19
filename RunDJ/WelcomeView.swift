//
//  WelcomeView5.swift
//  RunDJ
//
//  Created by Richard Cong on 3/15/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var showHelpSheet = false
    @State private var pulsate = false
    @State private var waveOffset: CGFloat = 0
    @State private var navigateToContentView = false
    
    //    Original red
    //    let gradientColors = [
    //        Color(red: 0.98, green: 0.3, blue: 0.3),
    //        Color(red: 0.9, green: 0.2, blue: 0.5)
    //    ]
    
    //    Blue to Purple
    //    let gradientColors = [
    //        Color(red: 0.2, green: 0.4, blue: 0.8),
    //        Color(red: 0.5, green: 0.2, blue: 0.9)
    //    ]
    
    //    Teal to Emerald
    //    let gradientColors = [
    //        Color(red: 0.0, green: 0.7, blue: 0.7),
    //        Color(red: 0.0, green: 0.8, blue: 0.4)
    //    ]
    
    //    Sunset (Orange to Pink)
    //    let gradientColors = [
    //        Color(red: 1.0, green: 0.6, blue: 0.0),
    //        Color(red: 0.9, green: 0.2, blue: 0.4)
    //    ]
    
    //    Forest (Light Green to Dark Green)
    //    let gradientColors = [
    //        Color(red: 0.4, green: 0.8, blue: 0.4),
    //        Color(red: 0.1, green: 0.5, blue: 0.3)
    //    ]
    
    //    Dark Mode (Dark Blue to Dark Purple)
    //    let gradientColors = [
    //        Color(red: 0.1, green: 0.2, blue: 0.3),
    //        Color(red: 0.2, green: 0.1, blue: 0.3)
    //    ]
    
    //     Midnight to Dawn (Deep Blue to Light Blue)
    //    let gradientColors = [
    //        Color(red: 0.05, green: 0.05, blue: 0.2),
    //        Color(red: 0.4, green: 0.7, blue: 0.9)
    //    ]
    
    //    Golden Hour (Yellow to Orange)
    //    let gradientColors = [
    //        Color(red: 1.0, green: 0.9, blue: 0.4),
    //        Color(red: 1.0, green: 0.5, blue: 0.0)
    //    ]
    
    //    Berry (Pink to Purple)
    //    let gradientColors = [
    //        Color(red: 0.9, green: 0.4, blue: 0.7),
    //        Color(red: 0.6, green: 0.2, blue: 0.8)
    //    ]
    
    //    Ocean (Light Blue to Deep Blue)
    //    let gradientColors = [
    //        Color(red: 0.4, green: 0.7, blue: 1.0),
    //        Color(red: 0.0, green: 0.3, blue: 0.6)
    //    ]
    
    //    Mint Chocolate (Mint Green to Dark Brown)
    //    let gradientColors = [
    //        Color(red: 0.6, green: 0.9, blue: 0.7),
    //        Color(red: 0.25, green: 0.15, blue: 0.1)
    //    ]
    
    //    Lime to Emerald
    let gradientColors = [
        Color(red: 0.7, green: 1.0, blue: 0.2),
        Color(red: 0.0, green: 0.6, blue: 0.3)
    ]
    
    //    Mint to Teal
    //    let gradientColors = [
    //        Color(red: 0.6, green: 1.0, blue: 0.8),
    //        Color(red: 0.0, green: 0.5, blue: 0.5)
    //    ]
    
    //    Avocado (Yellowish Green to Dark Green)
    //    let gradientColors = [
    //        Color(red: 0.6, green: 0.7, blue: 0.3),
    //        Color(red: 0.2, green: 0.4, blue: 0.1)
    //    ]
    
    //    Jungle (Medium Green to Deep Green)
    //    let gradientColors = [
    //        Color(red: 0.3, green: 0.7, blue: 0.4),
    //        Color(red: 0.05, green: 0.3, blue: 0.1)
    //    ]
    
    //    Spring (Light Yellow-Green to Bright Green)
    //    let gradientColors = [
    //        Color(red: 0.8, green: 0.9, blue: 0.5),
    //        Color(red: 0.3, green: 0.8, blue: 0.4)
    //    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic background with color gradient
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
                                .stroke(Color.white.opacity(0.15), lineWidth: 2)
                                .frame(width: width, height: 80)
                                .offset(y: height / 4 + CGFloat(i * 40))
                        }
                        
                        // Vertical EQ bars - left side
                        HStack(spacing: 4) {
                            ForEach(0..<8) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 3, height: CGFloat.random(in: 10...50))
                            }
                        }
                        .offset(x: width * 0.2, y: -height * 0.25)
                        
                        // Vertical EQ bars - right side
                        HStack(spacing: 4) {
                            ForEach(0..<8) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 3, height: CGFloat.random(in: 10...50))
                            }
                        }
                        .offset(x: width * 0.7, y: -height * 0.25)
                    }
                    .onAppear {
                        withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                            waveOffset += 2 * .pi
                        }
                    }
                }
                
                VStack {
                    // Header with app name and help button
                    HStack {
                        Text("Run DJ")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.leading, 20)
                        
                        Spacer()
                        
                        Button(action: {
                            showHelpSheet = true
                        }) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .padding(.trailing, 20)
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Center content with running and music theme
                    VStack(spacing: 25) {
                        // Animated icon combining running and music
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 130, height: 130)
                            
                            Circle()
                                .stroke(Color.white, lineWidth: pulsate ? 1 : 3)
                                .frame(width: pulsate ? 160 : 140, height: pulsate ? 160 : 140)
                                .onAppear {
                                    withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                        pulsate.toggle()
                                    }
                                }
                            
                            HStack(spacing: -5) {
                                Image(systemName: "figure.run")
                                    .font(.system(size: 44))
                                    .foregroundColor(.white)
                                
                                Image(systemName: "music.note")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                                    .offset(y: -10)
                            }
                        }
                        
                        VStack(spacing: 12) {
                            Text("FIND YOUR RHYTHM")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                            
                            Text("Running meets music. Perfectly synced.")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        
                        // Stats preview animation
                        HStack(spacing: 25) {
                            StatItem(icon: "flame.fill", value: "320", label: "CAL")
                            StatItem(icon: "waveform.path.ecg", value: "156", label: "BPM")
                            StatItem(icon: "location.fill", value: "5.2", label: "KM")
                        }
                        .padding(.vertical, 10)
                        
                        // Action buttons
                        VStack(spacing: 15) {
                            Button(action: {
                                navigateToContentView = true
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 16))
                                        .offset(x: 2)
                                    
                                    Text("START RUNNING")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(gradientColors[1])
                                .frame(width: 230, height: 55)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(Color.white)
                                )
                            }
                            
                            Button(action: {
                                // Explore playlists action
                            }) {
                                HStack {
                                    Image(systemName: "music.note.list")
                                        .font(.system(size: 14))
                                    
                                    Text("EXPLORE PLAYLISTS")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(width: 230, height: 55)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(Color.white, lineWidth: 2)
                                )
                            }
                        }
                        .padding(.top, 15)
                    }
                    
                    Spacer()
                    
                    // Footer
                    HStack(spacing: 2) {
                        Text("PERFECT BEATS FOR PERFECT RUNS")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(1)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.bottom, 15)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showHelpSheet) {
                HelpViewRhythm()
            }
            .navigationDestination(isPresented: $navigateToContentView) {
                ContentView()
            }
        }
        .sheet(isPresented: $showHelpSheet) {
            HelpViewRhythm()
        }
    }
}

struct SoundWave: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        var path = Path()
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let sine = sin(2 * .pi * frequency * x + phase)
            let y = midHeight + amplitude * sine
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 60)
    }
}

struct HelpViewRhythm: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.2, green: 0.1, blue: 0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Music wave pattern
            GeometryReader { geo in
                ForEach(0..<4) { i in
                    SoundWave(amplitude: 5, frequency: 0.05, phase: CGFloat(i) * 0.5)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.3, blue: 0.3).opacity(0.3),
                                    Color(red: 0.9, green: 0.2, blue: 0.5).opacity(0.3)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                        .offset(y: CGFloat(i) * 50 + 100)
                }
            }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("How can we help?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 25)
                
                // Main content
                ScrollView {
                    VStack(spacing: 25) {
                        // Help sections
                        HelpSectionRhythm(
                            title: "Getting Started",
                            items: [
                                HelpTopic(icon: "person.crop.circle.fill", title: "Create your profile", description: "Set up your fitness profile and personal stats."),
                                HelpTopic(icon: "music.note", title: "Connect music services", description: "Link your favorite streaming services."),
                                HelpTopic(icon: "figure.walk", title: "Calibrate your stride", description: "Get more accurate pace and distance tracking.")
                            ]
                        )
                        
                        HelpSectionRhythm(
                            title: "During Your Run",
                            items: [
                                HelpTopic(icon: "headphones", title: "BPM matching", description: "How the app matches music to your running pace."),
                                HelpTopic(icon: "waveform.path.ecg", title: "Real-time stats", description: "Understanding your performance metrics."),
                                HelpTopic(icon: "map", title: "Route tracking", description: "Saving and sharing your favorite routes.")
                            ]
                        )
                        
                        HelpSectionRhythm(
                            title: "Music Features",
                            items: [
                                HelpTopic(icon: "squares.below.rectangle", title: "Playlist creation", description: "Build the perfect running soundtrack."),
                                HelpTopic(icon: "arrow.clockwise", title: "Dynamic mixing", description: "How transitions work between tracks."),
                                HelpTopic(icon: "hand.raised", title: "Voice commands", description: "Control your music hands-free while running.")
                            ]
                        )
                        
                        // Contact support
                        VStack(spacing: 15) {
                            Text("Still need help?")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Button(action: {
                                // Contact support action
                            }) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 14))
                                    
                                    Text("Contact Support")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(width: 200, height: 45)
                                .background(
                                    RoundedRectangle(cornerRadius: 22.5)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.98, green: 0.3, blue: 0.3),
                                                    Color(red: 0.9, green: 0.2, blue: 0.5)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                            }
                        }
                        .padding(.top, 15)
                        .padding(.bottom, 25)
                    }
                }
            }
            .padding(.horizontal, 25)
        }
    }
}

struct HelpSectionRhythm: View {
    let title: String
    let items: [HelpTopic]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title.uppercased())
                .font(.system(size: 14, weight: .heavy))
                .tracking(1)
                .foregroundColor(Color(red: 0.98, green: 0.3, blue: 0.3))
                .padding(.bottom, 5)
            
            ForEach(items) { item in
                HStack(alignment: .top, spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.98, green: 0.3, blue: 0.3).opacity(0.2),
                                        Color(red: 0.9, green: 0.2, blue: 0.5).opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: item.icon)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(item.description)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 5)
            }
        }
    }
}

struct HelpTopic: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

struct WelcomeViewRhythm_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
