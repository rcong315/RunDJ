//
//  SettingsView.swift
//  RunDJ
//
//  Created on 5/13/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @Binding var isPresented: Bool
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
        NavigationStack {
            ZStack {
                Color.rundjBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Select which music sources to include when finding songs that match your running pace.")
                            .font(.system(size: 14))
                            .foregroundColor(.rundjTextSecondary)
                            .padding(.horizontal)
                            .padding(.top, 16)
                        
                        VStack(spacing: 8) {
                            ForEach(0..<sources.count, id: \.self) { index in
                                SourceRow(
                                    source: $sources[index],
                                    hasChanges: $hasChanges,
                                    checkForChanges: checkForChanges
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 100) // Space for buttons
                    
                    // Bottom Buttons
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                isPresented = false
                            }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(RundjButtonStyle(backgroundColor: .rundjCardBackground))
                            
                            Button("Save") {
                                let selectedSources = sources.filter { $0.isSelected }.map { $0.key }
                                settingsManager.musicSources = selectedSources
                                settingsManager.saveSettings()
                                onSave(selectedSources)
                                isPresented = false
                            }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(RundjButtonStyle(
                                backgroundColor: .rundjMusicGreen,
                                isDisabled: !hasChanges,
                                isMusic: true
                            ))
                            .disabled(!hasChanges)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                    .background(
                        Color.rundjCardBackground
                            .ignoresSafeArea(edges: .bottom)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
                    )
                }
            }
            .navigationTitle("Music Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingHelp = true }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.rundjAccent)
                    }
                }
            }
            .sheet(isPresented: $showingHelp) {
                HelpView(context: .settingsView)
            }
            .onAppear {
                for i in 0..<sources.count {
                    sources[i].isSelected = settingsManager.musicSources.contains(sources[i].key)
                }
                checkForChanges()
            }
        }
    }
    
    private func checkForChanges() {
        let selectedKeys = sources.filter { $0.isSelected }.map { $0.key }
        hasChanges = Set(selectedKeys) != Set(settingsManager.musicSources)
    }
}

struct SourceRow: View {
    @Binding var source: SourceItem
    @Binding var hasChanges: Bool
    let checkForChanges: () -> Void
    
    var body: some View {
        Button(action: {
            source.isSelected.toggle()
            checkForChanges()
        }) {
            HStack(spacing: 12) {
                Image(systemName: source.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(source.isSelected ? .rundjMusicGreen : .rundjTextTertiary)
                
                Text(source.name)
                    .font(.system(size: 16))
                    .foregroundColor(.rundjTextPrimary)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.rundjCardBackground)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SourceItem {
    var name: String
    var key: String
    var isSelected: Bool
}

// Preview
#Preview {
    SettingsView(
        isPresented: .constant(true),
        onSave: { _ in print("Preview save triggered") }
    )
    .environmentObject(SettingsManager.shared)
}
