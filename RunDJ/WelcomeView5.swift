import SwiftUI

struct DarkWelcomeView: View {
    @State private var selectedFeature = 0
    @State private var showLoginView = false
    
    private let features = [
        FeatureItem(
            title: "Rhythm Match",
            description: "We analyze your running cadence and match it with the perfect BPM from your music library",
            icon: "waveform.path"
        ),
        FeatureItem(
            title: "Smart Playlists",
            description: "Create dynamic playlists that automatically adjust to your running pace",
            icon: "music.note.list"
        ),
        FeatureItem(
            title: "Performance Analytics",
            description: "Track how music affects your running performance over time",
            icon: "chart.xyaxis.line"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Content
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    // Logo
                    ZStack {
                        Circle()
                            .fill(Color(#colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1)))
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .fill(Color(#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "waveform.path.ecg")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 60)
                    
                    // App name
                    Text("RUN DJ")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Your Personal Running DJ")
                        .font(.subheadline)
                        .foregroundColor(Color(#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)))
                }
                .padding(.bottom, 40)
                
                // Feature Carousel
                TabView(selection: $selectedFeature) {
                    ForEach(0..<features.count, id: \.self) { index in
                        FeatureCard(feature: features[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                .frame(height: 280)
                
                Spacer()
                
                // Connect Button
                Button(action: {
                    showLoginView = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "music.quarternote.3")
                            .font(.title3)
                        
                        Text("Connect with Spotify")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(
                        gradient: Gradient(colors: [
                            Color(#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)),
                            Color(#colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1))
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color(#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)).opacity(0.3), radius: 15, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                // Secondary Button
                Button(action: {
                    // Handle guest mode
                }) {
                    Text("Try without Spotify")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal)
        }
        .fullScreenCover(isPresented: $showLoginView) {
            DarkSpotifyLoginView()
        }
    }
}

struct FeatureItem {
    var title: String
    var description: String
    var icon: String
}

struct FeatureCard: View {
    var feature: FeatureItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(#colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1)))
                    .frame(width: 56, height: 56)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // Title and Description
            VStack(alignment: .leading, spacing: 12) {
                Text(feature.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(#colorLiteral(red: 0.08235294118, green: 0.08235294118, blue: 0.08235294118, alpha: 1)))
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }
}

struct DarkSpotifyLoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Content
            VStack(spacing: 32) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Spotify Logo Area
                VStack(spacing: 24) {
                    Circle()
                        .fill(Color(#colorLiteral(red: 0.1294117719, green: 0.7843137979, blue: 0.2235294171, alpha: 1)))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "music.note")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40)
                                .foregroundColor(.white)
                        )
                    
                    Text("Connect to Spotify")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("We'll need access to your Spotify account to create the perfect running playlists")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Login Button
                Button(action: {
                    isLoading = true
                    // Simulate authorization
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLoading = false
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    ZStack {
                        Text("Authorize")
                            .font(.headline)
                            .foregroundColor(.black)
                            .opacity(isLoading ? 0 : 1)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(#colorLiteral(red: 0.1294117719, green: 0.7843137979, blue: 0.2235294171, alpha: 1)))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct DarkWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        DarkWelcomeView()
    }
}
