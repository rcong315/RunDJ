import SwiftUI

struct WelcomeView: View {
    @State private var isAnimating: Bool = false
    @State private var showLoginView: Bool = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)), Color(#colorLiteral(red: 0.09019608051, green: 0, blue: 0.3019607961, alpha: 1))]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo and app name
                VStack(spacing: 15) {
                    Image(systemName: "waveform.path.ecg")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : -20)
                    
                    Text("Run DJ")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : -20)
                    
                    Text("Music that matches your pace")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : -10)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Feature highlights
                VStack(alignment: .leading, spacing: 25) {
                    FeatureRow(icon: "music.note", title: "Perfect BPM Match", description: "Syncs your music to your running cadence")
                    
                    FeatureRow(icon: "heart.fill", title: "Your Favorite Songs", description: "Uses your Spotify playlists and music preferences")
                    
                    FeatureRow(icon: "chart.bar.fill", title: "Performance Tracking", description: "Monitors your runs and adjusts music automatically")
                }
                .padding(.horizontal)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                
                Spacer()
                
                // Connect with Spotify button
                Button(action: {
                    showLoginView = true
                }) {
                    HStack {
                        Image("spotify-icon") // Add this asset to your project
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                        
                        Text("Connect with Spotify")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.7))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                
                // Privacy and terms
                HStack(spacing: 30) {
                    Button(action: {
                        // Show privacy policy
                    }) {
                        Text("Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Button(action: {
                        // Show terms of service
                    }) {
                        Text("Terms of Service")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.bottom, 20)
                .opacity(isAnimating ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                isAnimating = true
            }
        }
        .fullScreenCover(isPresented: $showLoginView) {
            SpotifyLoginView()
        }
    }
}

struct FeatureRow: View {
    var icon: String
    var title: String
    var description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct SpotifyLoginView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                Text("Connecting to Spotify")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // This would be a web view in a real app to handle Spotify OAuth
                // Simplified for this example
                Text("Authorization in progress...")
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    // This would actually handle Spotify auth
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Authorize")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(#colorLiteral(red: 0.1294117719, green: 0.9803921569, blue: 0.2235294132, alpha: 1)))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}
