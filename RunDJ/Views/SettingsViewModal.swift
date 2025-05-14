//
//  SettingsViewModal.swift
//  RunDJ
//
//  Created on 5/13/25.
//

import SwiftUI

struct SettingsViewModal: View {
    @Binding var isPresented: Bool
    var currentSources: [String]
    var bpm: Double
    var onSave: ([String]) -> Void
    
    @State private var showingHelp = false
    @State private var hasChanges = false
    
    @State private var sources = [
        SourceItem(name: "Top tracks", key: "top_tracks", isSelected: false),
        SourceItem(name: "Saved tracks", key: "saved_tracks", isSelected: false),
        SourceItem(name: "Playlists", key: "playlists", isSelected: false),
        SourceItem(name: "Top artists' top tracks", key: "top_artists_top_tracks", isSelected: false),
        SourceItem(name: "Top artists' albums", key: "top_artists_albums", isSelected: false),
        SourceItem(name: "Top artists' singles", key: "top_artists_singles", isSelected: false),
        SourceItem(name: "Followed artists' top tracks", key: "followed_artists_top_tracks", isSelected: false),
        SourceItem(name: "Followed artists' albums", key: "followed_artists_albums", isSelected: false),
        SourceItem(name: "Followed artists' singles", key: "followed_artists_singles", isSelected: false),
        SourceItem(name: "Saved Albums", key: "saved_albums", isSelected: false)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Music Sources")
                    .font(.title)
                    .padding()
                
                Spacer()
                
                Button(action: {
                    showingHelp = true
                }) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding()
            }
            
            List {
                ForEach(0..<sources.count, id: \.self) { index in
                    HStack {
                        Image(systemName: sources[index].isSelected ? "checkmark.square.fill" : "square")
                            .foregroundColor(sources[index].isSelected ? .green : .gray)
                            .onTapGesture {
                                sources[index].isSelected.toggle()
                                checkForChanges()
                            }
                        Text(sources[index].name)
                            .padding(.leading, 8)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        sources[index].isSelected.toggle()
                        checkForChanges()
                    }
                }
            }
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    isPresented = false
                }
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Save") {
                    // Pass the selected sources back to RunningView
                    let selectedSources = sources.filter { $0.isSelected }.map { $0.key }
                    onSave(selectedSources)
                    isPresented = false
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!hasChanges)
                .opacity(hasChanges ? 1.0 : 0.5)
            }
            .padding()
        }
        .onAppear {
            // Initialize the sources based on the current selection
            for i in 0..<sources.count {
                sources[i].isSelected = currentSources.contains(sources[i].key)
            }
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
    }
    
    // Check if the current selection differs from the initial selection
    private func checkForChanges() {
        let selectedKeys = sources.filter { $0.isSelected }.map { $0.key }
        
        // Check if the selected keys are different from the current sources
        if Set(selectedKeys) != Set(currentSources) {
            hasChanges = true
        } else {
            hasChanges = false
        }
    }
}

struct SourceItem {
    var name: String
    var key: String
    var isSelected: Bool
}

// Preview
#Preview {
    SettingsViewModal(
        isPresented: .constant(true), 
        currentSources: ["top_tracks", "saved_tracks"], 
        bpm: 160,
        onSave: { _ in }
    )
}
