import SwiftUI

struct NeonWelcomeView: View {
    @State private var activeAnimation = false
    @State private var showLoginView = false
    @State private var animateGradient = false
    
    // Particles for background animation
    @State private var particles: [ParticleModel] = []
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            // Animated gradient background
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    animateGradient ? Color.purple.opacity(0.2) : Color.blue.opacity(0.2),
                    Color.clear
                ]),
                center: .center,
                startRadius: animateGradient ? 100 : 200,
                endRadius: animateGradient ? 400 : 300
            )
            .ignoresSafeArea()
            .animation(
                Animation.easeInOut(duration: 4.0)
                    .repeatForever(autoreverses: true),
                value: animateGradient
            )
            
            // Particle effect
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .offset(y: particle.yOffset)
                }
            }
            
            // Main content
            VStack(spacing: 0) {
                // App name and logo
                VStack(spacing: 5) {
                    Text("SYNCHRO")
                        .font(.system(size: 42, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: Color.cyan.opacity(0.8), radius: activeAnimation ? 20 : 0, x: 0, y: 0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: activeAnimation)
                    
                    Text("BEAT")
                        .font(.system(size: 46, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: Color.pink.opacity(0.8), radius: activeAnimation ? 20 : 0, x: 0, y: 0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.5), value: activeAnimation)
                }
                .padding(.top, 70)
                
                // Neon rings visualization
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(lineWidth: 2)
                        .foregroundColor(.cyan)
                        .frame(width: 220, height: 220)
                        .shadow(color: .cyan, radius: 10)
                        .scaleEffect(activeAnimation ? 1.05 : 1.0)
                        .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: activeAnimation)
                    
                    // Middle ring
                    Circle()
                        .stroke(lineWidth: 2)
                        .foregroundColor(.pink)
                        .frame(width: 180, height: 180)
                        .shadow(color: .pink, radius: 10)
                        .scaleEffect(activeAnimation ? 1.1 : 0.95)
                        .animation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.2), value: activeAnimation)
                    
                    // Inner ring
                    Circle()
                        .stroke(lineWidth: 2)
                        .foregroundColor(.purple)
                        .frame(width: 140, height: 140)
                        .shadow(color: .purple, radius: 10)
                        .scaleEffect(activeAnimation ? 0.95 : 1.1)
                        .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.4), value: activeAnimation)
                    
                    // Sound wave lines
                    VStack(spacing: 6) {
                        ForEach(0..<7) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.cyan, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: getBarWidth(for: index), height: 4)
                                .shadow(color: .purple, radius: 5)
                                .scaleEffect(x: activeAnimation ? getRandomScale() : getRandomScale(), y: 1.0)
                                .animation(Animation.easeInOut(duration: Double.random(in: 0.5...1.5))
                                            .repeatForever(autoreverses: true)
                                            .delay(Double.random(in: 0...0.5)),
                                          value: activeAnimation)
                        }
                    }
                }
                .padding(.top, 30)
                .padding(.bottom, 40)
                
                // App description
                Text("MATCH YOUR RUNNING RHYTHM WITH\nYOUR SPOTIFY MUSIC")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                
                // Feature list
                VStack(spacing: 16) {
                    NeonFeatureItem(icon: "speedometer", text: "Adaptive BPM Detection")
                    NeonFeatureItem(icon: "music.note.list", text: "Smart Spotify Playlists")
                    NeonFeatureItem(icon: "waveform.path", text: "Real-time Cadence Sync")
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                
                Spacer()
                
                // Connect button
                Button(action: {
                    showLoginView = true
                }) {
                    Text("CONNECT WITH SPOTIFY")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.cyan, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .shadow(color: .cyan.opacity(0.6), radius: 15, x: 0, y: 0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
                
                // Skip option
                Button(action: {
                    // Handle skip action
                }) {
                    Text("EXPLORE WITHOUT SPOTIFY")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                        .padding(.bottom, 40)
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            activeAnimation = true
            animateGradient = true
            generateParticles()
        }
        .fullScreenCover(isPresented: $showLoginView) {
            NeonSpotifyLoginView()
        }
    }
    
    // Generate random particles for background effect
    private func generateParticles() {
        for i in 0..<30 {
            let particle = ParticleModel(
                id: i,
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                ),
                size: CGFloat.random(in: 2...6),
                color: [Color.cyan, Color.purple, Color.blue].randomElement()!,
                opacity: Double.random(in: 0.1...0.6),
                yOffset: CGFloat.random(in: -300...300)
            )
            particles.append(particle)
            
            // Animate particle movement
            withAnimation(Animation.linear(duration: Double.random(in: 10...30))
                            .repeatForever(autoreverses: false)) {
                particles[i].yOffset = CGFloat.random(in: -300...300) * -1
            }
        }
    }
    
    // Get varying bar widths for audio visualization
    private func getBarWidth(for index: Int) -> CGFloat {
        let widths: [CGFloat] = [45, 60, 80, 100, 80, 60, 45]
        return widths[index]
    }
    
    // Get random scale for animated bars
    private func getRandomScale() -> CGFloat {
        return CGFloat.random(in: 0.7...1.0)
    }
}

// Model for background particles
struct ParticleModel: Identifiable {
    var id: Int
    var position: CGPoint
    var size: CGFloat
    var color: Color
    var opacity: Double
    var yOffset: CGFloat
}

struct NeonFeatureItem: View {
    var icon: String
    var text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.cyan)
                .shadow(color: .cyan, radius: 5)
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color.black.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.cyan, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct NeonSpotifyLoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var animatePulse = false
    @State private var isConnecting = false
    @State private var progress: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Grid lines
            VStack(spacing: 20) {
                ForEach(0..<40) { _ in
                    Rectangle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(height: 1)
                }
            }
            .ignoresSafeArea()
            
            HStack(spacing: 20) {
                ForEach(0..<20) { _ in
                    Rectangle()
                        .fill(Color.cyan.opacity(0.1))
                        .frame(width: 1)
                }
            }
            .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 30) {
                // Header with back button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                            
                            Text("BACK")
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.purple, lineWidth: 1)
                        )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Spotify logo
                ZStack {
                    // Pulsing circles
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                        .frame(width: 140, height: 140)
                        .scaleEffect(animatePulse ? 1.2 : 1.0)
                        .opacity(animatePulse ? 0.2 : 0.5)
                    
                    Circle()
                        .stroke(Color.green.opacity(0.6), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(animatePulse ? 1.3 : 1.0)
                        .opacity(animatePulse ? 0.4 : 0.7)
                    
                    // Logo
                    Circle()
                        .fill(Color.green)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 36))
                                .foregroundColor(.black)
                        )
                        .shadow(color: Color.green.opacity(0.8), radius: 20)
                }
                .padding(.bottom, 40)
                
                // Title
                Text("SPOTIFY CONNECTION")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                
                // Description
                Text("We'll match your running cadence with your favorite Spotify tracks for the ultimate running experience")
                    .font(.system(size: 14, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                
                // Progress indicator (shows when connecting)
                if isConnecting {
                    VStack(spacing: 20) {
                        // Progress bar
                        ZStack(alignment: .leading) {
                            // Background bar
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            // Progress
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.green, .cyan]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: UIScreen.main.bounds.width * 0.8 * progress, height: 6)
                                .cornerRadius(3)
                        }
                        .frame(width: UIScreen.main.bounds.width * 0.8)
                        
                        // Status text
                        Text("CONNECTING TO SPOTIFY...")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 40)
                } else {
                    // Connect button
                    Button(action: {
                        isConnecting = true
                        
                        // Animate progress
                        withAnimation(Animation.easeInOut(duration: 0.5)) {
                            progress = 0.2
                        }
                        
                        // Simulate connection process with multiple steps
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            withAnimation(Animation.easeInOut(duration: 0.5)) {
                                progress = 0.5
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                            withAnimation(Animation.easeInOut(duration: 0.5)) {
                                progress = 0.8
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(Animation.easeInOut(duration: 0.5)) {
                                progress = 1.0
                            }
                        }
                        
                        // Return to previous screen after connection
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Text("CONNECT NOW")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding()
                            .frame(width: UIScreen.main.bounds.width * 0.8)
                            .background(Color.green)
                            .cornerRadius(30)
                            .shadow(color: Color.green.opacity(0.5), radius: 10)
                    }
                    .padding(.bottom, 24)
                    
                    // Privacy note
                    Text("This app uses Spotify's API and respects your privacy")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            // Start animations
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }
}

struct NeonWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        NeonWelcomeView()
    }
}
