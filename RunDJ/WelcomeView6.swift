import SwiftUI

struct ImmersiveWelcomeView: View {
    // Animation states
    @State private var isAnimating = false
    @State private var showContent = false
    @State private var pulseSize = false
    @State private var showStartButton = false
    
    // Screen transition state
    @State private var navigateToApp = false
    
    // Interactive states
    @State private var dragOffset: CGSize = .zero
    @State private var previousDragValue: CGSize = .zero
    
    // Music beat visualization
    @State private var beatCount = 0
    let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic background with motion effect
                ZStack {
                    // Base color
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    // Gradient overlays that move with device tilt
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.8, green: 0.1, blue: 0.3),
                                    Color(red: 0.6, green: 0.0, blue: 0.3).opacity(0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: geometry.size.width * 1.5)
                        .offset(x: -geometry.size.width * 0.3 + dragOffset.width * 0.2,
                                y: -geometry.size.height * 0.3 + dragOffset.height * 0.2)
                        .opacity(0.6)
                        .blur(radius: 60)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.0, green: 0.4, blue: 0.8),
                                    Color(red: 0.0, green: 0.2, blue: 0.6).opacity(0)
                                ]),
                                startPoint: .bottomTrailing,
                                endPoint: .topLeading
                            )
                        )
                        .frame(width: geometry.size.width * 1.5)
                        .offset(x: geometry.size.width * 0.3 - dragOffset.width * 0.2,
                                y: geometry.size.height * 0.3 - dragOffset.height * 0.2)
                        .opacity(0.6)
                        .blur(radius: 60)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = CGSize(
                                width: value.translation.width - previousDragValue.width,
                                height: value.translation.height - previousDragValue.height
                            )
                            dragOffset = CGSize(
                                width: dragOffset.width + translation.width,
                                height: dragOffset.height + translation.height
                            )
                            previousDragValue = value.translation
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                dragOffset = .zero
                                previousDragValue = .zero
                            }
                        }
                )
                
                // Beat visualization - circular waveform
                ZStack {
                    ForEach(0..<8) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.9, green: 0.2, blue: 0.3),
                                        Color(red: 0.0, green: 0.5, blue: 0.9)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .frame(
                                width: geometry.size.width * CGFloat(0.2 + (Double(i) * 0.1)),
                                height: geometry.size.width * CGFloat(0.2 + (Double(i) * 0.1))
                            )
                            .opacity(beatCount % 8 == i ? 0.8 : 0.2)
                            .scaleEffect(beatCount % 8 == i ? 1.05 : 1.0)
                    }
                }
                .opacity(isAnimating ? 1 : 0)
                .animation(.easeInOut(duration: 1.5), value: isAnimating)
                .onReceive(timer) { _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        beatCount = (beatCount + 1) % 8
                    }
                }
                
                // Content
                VStack(spacing: 5) {
                    Spacer()
                    
                    // App name with animated appearance
                    Text("BEATRUN")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(5)
                        .shadow(color: Color(red: 0.0, green: 0.5, blue: 0.9).opacity(0.8), radius: 20, x: 0, y: 0)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: showContent)
                    
                    // App icon combining running and music
                    ZStack {
                        // Running figure
                        Image(systemName: "figure.run")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .offset(x: -10)
                        
                        // Music notes
                        ForEach(0..<3) { i in
                            Image(systemName: "music.note")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .offset(
                                    x: CGFloat([40, 30, 50][i]),
                                    y: CGFloat([-20, -40, -10][i])
                                )
                                .opacity(pulseSize ? 1 : 0.5)
                                .scaleEffect(pulseSize ? 1.1 : 0.9)
                                .animation(
                                    Animation.easeInOut(duration: 1.2)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.3),
                                    value: pulseSize
                                )
                        }
                    }
                    .padding(.vertical, 40)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.5), value: showContent)
                    
                    // Tagline
                    Text("SYNC YOUR STEP TO THE BEAT")
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(2)
                        .padding(.bottom, 40)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.7), value: showContent)
                    
                    // Feature descriptions with icons
                    VStack(spacing: 24) {
                        ImmersiveFeatureRow(
                            icon: "waveform.path",
                            title: "ADAPTIVE RHYTHM",
                            description: "Music that automatically matches your running cadence",
                            delay: 0.9
                        )
                        
                        ImmersiveFeatureRow(
                            icon: "headphones",
                            title: "PERSONALIZED PLAYLISTS",
                            description: "Curated music that fits your pace and preferences",
                            delay: 1.1
                        )
                        
                        ImmersiveFeatureRow(
                            icon: "chart.bar.fill",
                            title: "PERFORMANCE TRACKING",
                            description: "Analyze how music affects your running metrics",
                            delay: 1.3
                        )
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.8), value: showContent)
                    
                    // Start experience button
                    Button(action: {
                        withAnimation {
                            navigateToApp = true
                        }
                    }) {
                        Text("START RUNNING")
                            .font(.system(size: 18, weight: .bold, design: .default))
                            .foregroundColor(.black)
                            .padding(.vertical, 18)
                            .padding(.horizontal, 40)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.9, green: 0.2, blue: 0.3),
                                        Color(red: 0.0, green: 0.5, blue: 0.9)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(30)
                            .shadow(color: Color(red: 0.0, green: 0.5, blue: 0.9).opacity(0.5), radius: 15, x: 0, y: 5)
                    }
                    .scaleEffect(showStartButton ? 1 : 0.8)
                    .opacity(showStartButton ? 1 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(1.5), value: showStartButton)
                    
                    // Sign in option
                    Button(action: {
                        // Sign in action
                    }) {
                        Text("Already have an account? Sign In")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    }
                    .opacity(showStartButton ? 1 : 0)
                    .animation(.easeIn.delay(1.7), value: showStartButton)
                }
                .padding()
                
                // Navigation link to the next screen
                NavigationLink(
                    destination: MainAppView(),
                    isActive: $navigateToApp,
                    label: { EmptyView() }
                )
            }
            .preferredColorScheme(.dark)
            .onAppear {
                // Start animations in sequence
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        isAnimating = true
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation {
                        showContent = true
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    pulseSize = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showStartButton = true
                }
            }
        }
    }
}

// Feature row with animated appearance
struct ImmersiveFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.9, green: 0.2, blue: 0.3).opacity(0.3),
                            Color(red: 0.0, green: 0.5, blue: 0.9).opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            
            // Text content
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(delay)) {
                isVisible = true
            }
        }
    }
}

// Placeholder for main app view
struct MainAppView: View {
    var body: some View {
        Text("Main App Experience")
            .font(.largeTitle)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

struct ImmersiveWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ImmersiveWelcomeView()
        }
    }
}
