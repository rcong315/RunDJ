import SwiftUI

struct AlternateWelcomeView: View {
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    // Motion effect states
    @State private var xOffset: CGFloat = 0
    @State private var lastXValue: CGFloat = 0
    
    // Onboarding slides content
    let slides = [
        OnboardingSlide(
            title: "RunBeat",
            subtitle: "Run to Your Own Beat",
            description: "Experience music that automatically syncs with your running tempo",
            imageName: "figure.run"
        ),
        OnboardingSlide(
            title: "Smart Matching",
            subtitle: "Perfect Rhythm",
            description: "Our algorithm selects songs that match your pace for maximum performance",
            imageName: "waveform.path"
        ),
        OnboardingSlide(
            title: "Track Progress",
            subtitle: "See Your Improvement",
            description: "Monitor your pace, distance, and how your music changes with your rhythm",
            imageName: "chart.bar.xaxis"
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                // Dynamic background elements (music equalizer style)
                VStack(spacing: 5) {
                    ForEach(0..<20) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.purple, .blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: CGFloat.random(in: 100...250), height: 4)
                            .offset(x: isAnimating ? CGFloat.random(in: -30...30) : 0)
                            .animation(
                                Animation.easeInOut(duration: Double.random(in: 0.8...2.0))
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.05),
                                value: isAnimating
                            )
                            .opacity(0.3)
                    }
                }
                .offset(y: -geometry.size.height * 0.15)
                
                // Content slides
                TabView(selection: $currentPage) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        VStack(spacing: 40) {
                            // Top title area
                            VStack(spacing: 16) {
                                Text(slides[index].title)
                                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text(slides[index].subtitle)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                            }
                            
                            // Image with interactive motion effect
                            Image(systemName: slides[index].imageName)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white)
                                .frame(height: 160)
                                .padding()
                                .background(
                                    ZStack {
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    gradient: Gradient(colors: [.purple.opacity(0.7), .blue.opacity(0.1)]),
                                                    center: .center,
                                                    startRadius: 5,
                                                    endRadius: 120
                                                )
                                            )
                                        
                                        // Pulsing circles
                                        ForEach(0..<3) { i in
                                            Circle()
                                                .stroke(LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                                                .scaleEffect(isAnimating ? 1 + CGFloat(i) * 0.2 : 0.8)
                                                .opacity(isAnimating ? 0 : 0.5)
                                                .animation(
                                                    Animation.easeInOut(duration: 1.5)
                                                        .repeatForever(autoreverses: false)
                                                        .delay(Double(i) * 0.5),
                                                    value: isAnimating
                                                )
                                        }
                                    }
                                )
                                .offset(x: xOffset)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let xChange = value.translation.width - lastXValue
                                            lastXValue = value.translation.width
                                            xOffset += xChange * 0.3
                                        }
                                        .onEnded { _ in
                                            withAnimation(.spring()) {
                                                xOffset = 0
                                                lastXValue = 0
                                            }
                                        }
                                )
                            
                            // Description
                            Text(slides[index].description)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 30)
                                .padding(.top, 20)
                            
                            Spacer()
                        }
                        .tag(index)
                        .padding(.top, 60)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Bottom controls
                VStack {
                    Spacer()
                    
                    // Progress dots
                    HStack(spacing: 10) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.white : Color.gray.opacity(0.5))
                                .frame(width: 10, height: 10)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    .padding(.bottom, 30)
                    
                    // Action buttons
                    if currentPage == slides.count - 1 {
                        Button(action: {
                            // Start app experience
                        }) {
                            Text("START RUNNING")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .padding(.horizontal, 30)
                        }
                        
                        Button(action: {
                            // Handle sign in
                        }) {
                            Text("I already have an account")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                                .padding(.bottom, 30)
                        }
                    } else {
                        Button(action: {
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            Text("NEXT")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.purple, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .padding(.horizontal, 30)
                        }
                        
                        Button(action: {
                            withAnimation {
                                currentPage = slides.count - 1
                            }
                        }) {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                                .padding(.bottom, 30)
                        }
                    }
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// Structure for onboarding content
struct OnboardingSlide {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
}

// Preview
struct AlternateWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        AlternateWelcomeView()
            .preferredColorScheme(.dark)
    }
}
