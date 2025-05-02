//
//  StartView.swift
//  RunDJ
//
//  Created on 4/29/25.
//

import SwiftUI

struct StartView: View {
    @StateObject private var spotifyManager = SpotifyManager.shared
    
    @State private var showSpotifyError = false
    @State private var errorMessage = ""
    @State private var showingHelp = false
    @State private var navigateToContent = false
    
    @State private var sources = [
        SourceItem(name: "Top tracks", key: "top_tracks", isSelected: true),
        SourceItem(name: "Saved tracks", key: "saved_tracks", isSelected: true),
        SourceItem(name: "Playlists", key: "playlists", isSelected: true),
        SourceItem(name: "Top artists' top tracks", key: "top_artists_top_tracks", isSelected: true),
        SourceItem(name: "Top artists' albums", key: "top_artists_albums", isSelected: false),
        SourceItem(name: "Top artists' singles", key: "top_artists_singles", isSelected: false),
        SourceItem(name: "Followed artists' top tracks", key: "followed_artists_top_tracks", isSelected: true),
        SourceItem(name: "Followed artists' albums", key: "followed_artists_albums", isSelected: false),
        SourceItem(name: "Followed artists' singles", key: "followed_artists_singles", isSelected: false),
        SourceItem(name: "Saved Albums", key: "saved_albums", isSelected: true)
    ]
    
    var body: some View {
        NavigationView {
            VStack() {
                HStack {
                    Spacer()
                    Button(action: {
                        showingHelp = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    .padding()
                }
                
                Text("Connect RunDJ to your Spotify Account")
                    .font(.headline)
                Button(action: {
                    if spotifyManager.connectionState != .connected {
                        spotifyManager.initiateSession()
                    }
                }) {
                    Text("Connect Spotify")
                        .padding()
                        .background(buttonColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Text(connectionStateText)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray)
                
                Text("Select Music Sources")
                    .font(.title)
                List {
                    ForEach(0..<sources.count, id: \.self) { index in
                        HStack {
                            Image(systemName: sources[index].isSelected ? "checkmark.square.fill" : "square")
                                .foregroundColor(sources[index].isSelected ? .green : .gray)
                                .onTapGesture {
                                    sources[index].isSelected.toggle()
                                }
                            Text(sources[index].name)
                                .padding(.leading, 8)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            sources[index].isSelected.toggle()
                        }
                    }
                }
                
                NavigationLink(destination: BPMView(sources: sources.filter { $0.isSelected }.map { $0.key })) {
                    Text("Confirm Selection")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                //TODO: Please connect to spotify first
            }
        }
        .onChange(of: spotifyManager.connectionState) { _, newState in
            switch newState {
            case .error(let message):
                errorMessage = message
                showSpotifyError = true
            default:
                break
            }
        }
        .alert(isPresented: $showSpotifyError) {
            return Alert(
                title: Text("Spotify Connection Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
    }
    
    private var connectionStateText: String {
        switch spotifyManager.connectionState {
        case .connected:
            return "Connected "
        case .error(let message):
            return "Error: \(message)"
        default:
            return "Not Connected"
        }
    }
    
    private var buttonColor: Color {
        switch spotifyManager.connectionState {
        case .connected:
            return .gray
        case .disconnected, .error:
            return .green
        }
    }
}

// Model for playlist items
struct SourceItem {
    var name: String
    var key: String
    var isSelected: Bool
}

#Preview {
    StartView()
}
