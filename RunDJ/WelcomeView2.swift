import SwiftUI

struct MinimalWelcomeView: View {
    @State private var showLoginView = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            VStack(spacing: 24) {
                // App Logo
                Circle()
                    .fill(Color.black)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "waveform")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40)
                            .foregroundColor(.white)
                    )
                    .padding(.top, 60)
                
                // App Name and Tagline
                VStack(spacing: 8) {
                    Text("Run DJ")
                        .font(.system(size: 32, weight: .bold, design: .default))
                    
                    Text("Your pace. Your music. In sync.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 60)
            
            // Illustration
            Image(systemName: "figure.run")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 120)
                .foregroundColor(.black)
                .padding(.bottom, 60)
            
            Spacer()
            
            // Bottom Action Section
            VStack(spacing: 16) {
                // Connect with Spotify Button
                Button(action: {
                    showLoginView = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "music.note")
                        Text("Connect with Spotify")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                
                // Skip Button
                Button(action: {
                    // Handle skip action
                }) {
                    Text("Explore First")
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                // Terms and Privacy
                HStack(spacing: 24) {
                    Text("Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("Terms of Use")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.white)
        .fullScreenCover(isPresented: $showLoginView) {
            MinimalSpotifyLoginView()
        }
    }
}

struct MinimalSpotifyLoginView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 32) {
            // Header with Close Button
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .padding(12)
                        .background(Color.black.opacity(0.05))
                        .clipShape(Circle())
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            
            Spacer()
            
            // Spotify Logo
            Image(systemName: "music.note.list")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.green)
            
            // Instruction Text
            VStack(spacing: 8) {
                Text("Connect Your Spotify")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("We'll match your favorite songs to your running rhythm")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Authorize Button
            Button(action: {
                // Handle Spotify authorization
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Authorize")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 32)
        }
    }
}

struct MinimalWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        MinimalWelcomeView()
    }
}
