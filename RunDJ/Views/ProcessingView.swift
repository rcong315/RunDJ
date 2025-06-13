//
//  ProcessingView.swift
//  RunDJ
//
//  Created on 6/7/25.
//

import SwiftUI
import Sentry

struct ProcessingView: View {
    @StateObject private var rundjService = RunDJService.shared
    @StateObject private var spotifyManager = SpotifyManager.shared
    @State private var processingMessage = "Setting up your music library..."
    @State private var progress = 0.0
    @State private var isProcessing = true
    @State private var checkTimer: Timer?
    @Environment(\.dismiss) var dismiss
    
    let onProcessingComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.rundjBackground
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Icon
                Image(systemName: "music.note.list")
                    .font(.system(size: 60))
                    .foregroundColor(.rundjMusicGreen)
                    .symbolEffect(.pulse.wholeSymbol, options: .repeating, value: isProcessing)
                
                // Title
                Text("Processing Your Music")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.rundjTextPrimary)
                
                // Message
                Text(processingMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.rundjTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Progress indicator
                if isProcessing {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.rundjMusicGreen)
                        .padding()
                    
                    Text("This may take a few minutes...")
                        .font(.system(size: 14))
                        .foregroundColor(.rundjTextSecondary)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.rundjMusicGreen)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Continue button (only shown when complete)
                if !isProcessing {
                    Button(action: {
                        onProcessingComplete()
                        dismiss()
                    }) {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RundjPrimaryButtonStyle(isDisabled: false, isMusic: true))
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding()
        }
        .onAppear {
            startProcessingCheck()
        }
        .onDisappear {
            checkTimer?.invalidate()
        }
    }
    
    private func startProcessingCheck() {
        // Check immediately
        checkProcessingStatus()
        
        // Then check every 3 seconds
        checkTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            checkProcessingStatus()
        }
    }
    
    private func checkProcessingStatus() {
        guard let token = spotifyManager.getAccessToken() else {
            processingMessage = "Unable to check status. Please try again."
            isProcessing = false
            return
        }
        
        rundjService.checkProcessingStatus(accessToken: token) { status in
            DispatchQueue.main.async {
                guard let status = status else {
                    processingMessage = "Unable to check status. Please try again."
                    isProcessing = false
                    return
                }
                
                if status.status == "complete" {
                    withAnimation {
                        processingMessage = status.message
                        isProcessing = false
                    }
                    checkTimer?.invalidate()
                    
                    let breadcrumb = Breadcrumb()
                    breadcrumb.level = .info
                    breadcrumb.category = "processing"
                    breadcrumb.message = "Music processing completed"
                    SentrySDK.addBreadcrumb(breadcrumb)
                } else {
                    processingMessage = status.message
                }
            }
        }
    }
}

#Preview {
    ProcessingView(onProcessingComplete: {})
}
