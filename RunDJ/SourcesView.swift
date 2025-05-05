//
//  SourcesView.swift
//  RunDJ
//
//  Created on 4/29/25.
//

import SwiftUI

struct SourcesView: View {
    
    @State private var showingHelp = false
    
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
            VStack(spacing: 0) {
                
                //                HStack() {
                //                    Spacer()
                //                    Spacer()
                //                    Spacer()
                //                    Spacer()
                //                    Text("Select Music Sources")
                //                        .font(.title2)
                //                        .frame(maxWidth: .infinity)
                //                    Spacer()
                //                    Button(action: {
                //                        showingHelp = true
                //                    }) {
                //                        Image(systemName: "questionmark.circle")
                //                            .font(.title2)
                //                            .foregroundColor(.blue)
                //                    }
                //                }
                //                .padding()
                
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
                
                Spacer()
                
                NavigationLink(destination: BPMView(sources: sources.filter { $0.isSelected }.map { $0.key })) {
                    Text("Confirm Selection")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Setting Spotify Sources")
                        .font(.title2)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingHelp = true
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
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
    SourcesView()
}
