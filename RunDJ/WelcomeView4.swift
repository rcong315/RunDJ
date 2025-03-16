import SwiftUI

struct DynamicWelcomeView: View {
    @State private var isAnimating = false
    @State private var showLoginView = false
    
    // Animated wave properties
    @State private var waveOffset = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic background
                Color(#colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1))
                    .ignoresSafeArea()
                
                // Animated waves
                VStack {
                    Spacer()
                    
                    ZStack {
                        // First wave
                        WaveShape(offset: waveOffset, percent: 1.2)
                            .fill(Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 0.6)))
                            .frame(height: 100)
                        
                        // Second wave
                        WaveShape(offset: waveOffset + 0.5, percent: 1.0)
                            .fill(Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 0.4)))
                            .frame(height: 120)
                            .offset(y: 10)
                            
                        // Third wave
                        WaveShape(offset: waveOffset + 1.0, percent: 0.8)
                            .fill(Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 0.2)))
                            .frame(height: 140)
                            .offset(y: 20)
                    }
                    .frame(height: 140)
                    
                    Rectangle()
                        .fill(Color(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 0.6)))
                        .frame(height: geometry.size.height * 0.3)
                }
                .ignoresSafeArea()
                
                // Content
                VStack {
                    // Header section
                    HStack(alignment: .center) {
                        // Pulsing logo
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 100, height: 100)
                                .scaleEffect(isAnimating ? 1.1 : 1.0)
                                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                            
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .scaleEffect(isAnimating ? 1.2 : 1.0)
                                .animation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "headphones")
                                .font(.system(size: 30, weight: .medium))
                                .foregroundColor(Color(#colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)))
                        }
                        
                        // App name with animated typewriter effect
                        VStack(alignment: .leading) {
                            Text("RUN")
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("DJ")
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Benefits visualization
                    HStack(spacing: 30) {
                        BenefitCard(
                            icon: "hare",
                            title: "Pace",
                            description: "Improve your cadence"
                        )
                        
                        BenefitCard(
                            icon: "heart.fill",
                            title: "Health",
                            description: "Optimize workouts"
                        )
                        
                        BenefitCard(
                            icon: "flame.fill",
                            title: "Energy",
                            description: "Boost performance"
                        )
                    }
                    .padding(.horizontal)
                    .offset(y: isAnimating ? 0 : 50)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(Animation.easeOut(duration: 0.8).delay(0.5), value: isAnimating)
                    
                    Spacer()
                    
                    // Tagline
                    Text("Your running pace matched with the perfect beat")
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        .offset(y: isAnimating ? 0 : 20)
                        .opacity(isAnimating ? 1 : 0)
                        .animation(Animation.easeOut(duration: 0.8).delay(0.7), value: isAnimating)
                    
                    // Connect button
                    Button(action: {
                        showLoginView = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "music.note")
                                .font(.title3)
                            
                            Text("CONNECT WITH SPOTIFY")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(Color(#colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)))
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(28)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 32)
                    .offset(y: isAnimating ? 0 : 30)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(Animation.easeOut(duration: 0.8).delay(0.9), value: isAnimating)
                    
                    // Skip option
                    Button(action: {
                        // Handle skip action
                    }) {
                        Text("Continue without music")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 16)
                            .padding(.bottom, 40)
                    }
                    .offset(y: isAnimating ? 0 : 30)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(Animation.easeOut(duration: 0.8).delay(1.0), value: isAnimating)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            isAnimating = true
            // Start wave animation
            withAnimation(Animation.linear(duration: 8).repeatForever(autoreverses: false)) {
                waveOffset = 2.0
            }
        }
        .fullScreenCover(isPresented: $showLoginView) {
            DynamicSpotifyLoginView()
        }
    }
}

// Wave shape for animated background
struct WaveShape: Shape {
    var offset: Double
    var percent: Double
    
    var animatableData: Double {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height * percent
        let wavelength = width / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        // Create wave pattern
        for x in stride(from: 0, through: width, by: 5) {
            let relativeX = x / wavelength
            let sine = sin(relativeX + offset)
            let y = midHeight + sine * 20
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Complete the path
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct BenefitCard: View {
    var icon: String
    var title: String
    var description: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(description)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(height: 140)
        .padding(.horizontal, 5)
    }
}

struct DynamicSpotifyLoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isConnecting = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                // Logo and title
                VStack(spacing: 24) {
                    // Animated vinyl record
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 160, height: 160)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color(#colorLiteral(red: 0.1294117719, green: 0.7843137979, blue: 0.2235294171, alpha: 1)), lineWidth: 6)
                            )
                            .overlay(
                                Circle()
                                    .fill(Color(#colorLiteral(red: 0.1294117719, green: 0.7843137979, blue: 0.2235294171, alpha: 1)))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .fill(Color.black)
                                            .frame(width: 16, height: 16)
                                    )
                            )
                        
                        // Vinyl grooves
                        ForEach(0..<8) { i in
                            Circle()
                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                                .frame(width: CGFloat(130 - i * 10), height: CGFloat(130 - i * 10))
                        }
                    }
                    .rotationEffect(Angle(degrees: isConnecting ? 360 : 0))
                    .animation(isConnecting ? Animation.linear(duration: 3).repeatForever(autoreverses: false) : Animation.default, value: isConnecting)
                    
                    Text("Spotify Connection")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Connect your Spotify account to sync your favorite music with your running rhythm")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Connection button
                Button(action: {
                    isConnecting = true
                    // Simulate connection process
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    HStack(spacing: 12) {
                        if isConnecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            
                            Text("Connecting...")
                                .font(.headline)
                                .foregroundColor(.black)
                        } else {
                            Image(systemName: "music.note")
                                .font(.headline)
                            
                            Text("Connect Now")
                                .font(.headline)
                                .foregroundColor(.black)
                        }
                    }
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(Color(#colorLiteral(red: 0.1294117719, green: 0.7843137979, blue: 0.2235294171, alpha: 1)))
                    .cornerRadius(28)
                }
                .disabled(isConnecting)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
                
                // Terms info
                if !isConnecting {
                    Text("By connecting, you agree to our Terms and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 30)
                }
            }
        }
    }
}

struct DynamicWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        DynamicWelcomeView()
    }
}
