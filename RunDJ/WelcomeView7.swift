import SwiftUI

struct MinimalistWelcomeView: View {
    @State private var isSignInExpanded = false
    @State private var isPulsing = false
    @State private var animateGradient = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.97),
                        Color(red: 0.90, green: 0.90, blue: 0.95)
                    ]),
                    startPoint: animateGradient ? .topLeading : .bottomLeading,
                    endPoint: animateGradient ? .bottomTrailing : .topTrailing
                )
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    withAnimation(.linear(duration: 10).repeatForever(autoreverses: true)) {
                        animateGradient.toggle()
                    }
                }
                
                VStack(spacing: 0) {
                    // Header space
                    Spacer()
                        .frame(height: geometry.size.height * 0.1)
                    
                    // App name and icon
                    VStack(spacing: 15) {
                        // Tempo visualization
                        HStack(spacing: 4) {
                            ForEach(0..<5) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.black)
                                    .frame(width: 3, height: CGFloat(10 + (i * 8)))
                                    .offset(y: isPulsing ? -5 : 5)
                                    .animation(
                                        Animation.easeInOut(duration: 0.6 + Double(i) * 0.1)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.1),
                                        value: isPulsing
                                    )
                            }
                            
                            Text("TEMPO")
                                .font(.system(size: 22, weight: .black, design: .default))
                                .tracking(2)
                                .foregroundColor(.black)
                                .padding(.leading, 8)
                            
                            ForEach(0..<5) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.black)
                                    .frame(width: 3, height: CGFloat(10 + ((4 - i) * 8)))
                                    .offset(y: isPulsing ? 5 : -5)
                                    .animation(
                                        Animation.easeInOut(duration: 0.6 + Double(i) * 0.1)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.1),
                                        value: isPulsing
                                    )
                            }
                        }
                        .padding(.bottom, 5)
                        
                        Text("Run to the beat of your own rhythm")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 60)
                    
                    // Main illustration
                    ZStack {
                        // Circular background
                        Circle()
                            .fill(Color.white)
                            .frame(width: min(geometry.size.width * 0.8, 300), height: min(geometry.size.width * 0.8, 300))
                            .shadow(color: Color.black.opacity(0.05), radius: 30, x: 0, y: 10)
                        
                        // Runner silhouette
                        Image(systemName: "figure.run")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.black)
                            .frame(width: min(geometry.size.width * 0.4, 150), height: min(geometry.size.width * 0.4, 150))
                        
                        // Music notes
                        ForEach(0..<3) { i in
                            Image(systemName: "music.note")
                                .font(.system(size: 24))
                                .foregroundColor(.black.opacity(0.7))
                                .offset(
                                    x: CGFloat([40, 50, 30][i]),
                                    y: CGFloat([-30, -60, -20][i])
                                )
                                .opacity(isPulsing ? 1.0 : 0.3)
                                .animation(
                                    Animation.easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.3),
                                    value: isPulsing
                                )
                        }
                        
                        // Circular beats
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                .frame(width: CGFloat(70 + (i * 40)), height: CGFloat(70 + (i * 40)))
                                .scaleEffect(isPulsing ? 1.1 : 1.0)
                                .animation(
                                    Animation.easeInOut(duration: 1.2)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.2),
                                    value: isPulsing
                                )
                        }
                    }
                    .padding(.bottom, 60)
                    
                    // Feature highlights
                    VStack(spacing: 20) {
                        FeatureItem(icon: "metronome.fill", text: "Music that matches your running cadence")
                        FeatureItem(icon: "bolt.horizontal.fill", text: "Find your perfect running flow")
                        FeatureItem(icon: "heart.fill", text: "Improve your performance naturally")
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                    
                    // Get started button
                    Button(action: {
                        // Navigate to main app
                    }) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.black)
                            .cornerRadius(30)
                            .padding(.horizontal, 30)
                    }
                    
                    // Sign in options
                    VStack {
                        Button(action: {
                            withAnimation(.spring()) {
                                isSignInExpanded.toggle()
                            }
                        }) {
                            Text("Already have an account?")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(Color.gray)
                                .padding(.top, 20)
                        }
                        
                        if isSignInExpanded {
                            HStack(spacing: 20) {
                                // Email sign in
                                Button(action: {
                                    // Sign in action
                                }) {
                                    Text("Sign In")
                                        .font(.system(size: 16, weight: .medium, design: .default))
                                        .foregroundColor(.black)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 30)
                                        .background(
                                            RoundedRectangle(cornerRadius: 30)
                                                .stroke(Color.black, lineWidth: 1)
                                        )
                                }
                                
                                // Apple sign in
                                Button(action: {
                                    // Apple sign in action
                                }) {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Circle().fill(Color.black))
                                }
                            }
                            .padding(.top, 10)
                            .transition(.opacity)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            isPulsing = true
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

struct MinimalistWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        MinimalistWelcomeView()
    }
}
