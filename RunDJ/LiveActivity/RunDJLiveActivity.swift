//
//  RunDJLiveActivity.swift
//  RunDJ
//
//  Created on 6/8/25.
//

import ActivityKit
import SwiftUI
import WidgetKit
import AppIntents

// MARK: - App Intents for Background Feedback

struct ThumbsUpIntent: AppIntent {
    static var title: LocalizedStringResource = "Like Song"
    static var description = IntentDescription("Send positive feedback for the current song")
    
    func perform() async throws -> some IntentResult {
        // Store feedback request in shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: "group.com.rundj.RunDJ") {
            var pendingFeedback = sharedDefaults.array(forKey: "pendingFeedback") as? [[String: String]] ?? []
            let feedback: [String: String] = [
                "type": "LIKE",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            pendingFeedback.append(feedback)
            sharedDefaults.set(pendingFeedback, forKey: "pendingFeedback")
            
            // Store immediate feedback for Live Activity visual feedback
            sharedDefaults.set("LIKE", forKey: "lastFeedbackType")
            sharedDefaults.set(Date(), forKey: "lastFeedbackTime")
        }
        return .result()
    }
}

struct ThumbsDownIntent: AppIntent {
    static var title: LocalizedStringResource = "Dislike Song"
    static var description = IntentDescription("Send negative feedback and skip to next song")
    
    func perform() async throws -> some IntentResult {
        // Store feedback request in shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: "group.com.rundj.RunDJ") {
            var pendingFeedback = sharedDefaults.array(forKey: "pendingFeedback") as? [[String: String]] ?? []
            let feedback: [String: String] = [
                "type": "DISLIKE",
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
            pendingFeedback.append(feedback)
            sharedDefaults.set(pendingFeedback, forKey: "pendingFeedback")
            
            // Store immediate feedback for Live Activity visual feedback
            sharedDefaults.set("DISLIKE", forKey: "lastFeedbackType")
            sharedDefaults.set(Date(), forKey: "lastFeedbackTime")
        }
        return .result()
    }
}

// MARK: - Activity Attributes

struct RunDJActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic content that updates
        var stepsPerMinute: Int
        var distance: Double // in miles/km
        var duration: TimeInterval
        var pace: String // formatted pace string
        var currentSong: String
        var currentArtist: String
        var songBPM: Int
        var isPlaying: Bool
        var elapsedTime: Date // For timer
        
        var lastFeedbackType: String? // "LIKE", "DISLIKE", or nil
        var lastFeedbackTime: Date? // When the feedback was given
        var useMetricUnits: Bool
    }
    
    // Static content (set when activity starts)
    var targetBPM: Int
    var startTime: Date
    var activityType: String // "Run" or "Walk"
}

// MARK: - Live Activity Widget

struct RunDJLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunDJActivityAttributes.self) { context in
            // Lock Screen View
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.rundjBackground)
                .activitySystemActionForegroundColor(Color.rundjMusicGreen)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded View (Long press)
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "figure.run")
                            .font(.title2)
                            .foregroundColor(.rundjMusicGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(context.state.stepsPerMinute)")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.rundjMusicGreen)
                            Text("SPM")
                                .font(.caption2)
                                .foregroundColor(.rundjTextSecondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(context.state.distance.formatted(.number.precision(.fractionLength(1))) + " \(context.state.useMetricUnits ? "km" : "mi")")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.rundjAccent)
                        Text(context.state.pace)
                            .font(.caption)
                            .foregroundColor(.rundjTextSecondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        // Timer
                        Text(timerInterval: context.attributes.startTime...Date.distantFuture,
                             countsDown: false,
                             showsHours: true)
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundColor(.rundjTextPrimary)
                        .frame(width: 80)
                        .multilineTextAlignment(.center)
                        
                        // Now Playing
                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: context.state.isPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                    .font(.caption2)
                                    .foregroundColor(.rundjMusicGreen)
                                Text(context.state.currentSong)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .foregroundColor(.rundjTextPrimary)
                            }
                            Text("\(context.state.currentArtist) • \(context.state.songBPM) BPM")
                                .font(.caption2)
                                .foregroundColor(.rundjTextSecondary)
                                .lineLimit(1)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 20) {
                        // Helper function for Dynamic Island feedback appearance
                        let isRecentFeedback = {
                            guard let feedbackTime = context.state.lastFeedbackTime else { return false }
                            return Date().timeIntervalSince(feedbackTime) < 2.0
                        }()
                        
                        // Thumbs up button
                        Button(intent: ThumbsUpIntent()) {
                            Label("Like", systemImage: "hand.thumbsup.fill")
                                .font(.caption)
                                .foregroundColor(.rundjMusicGreen)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.rundjMusicGreen.opacity(
                                            isRecentFeedback && context.state.lastFeedbackType == "LIKE" ? 0.6 : 0.2
                                        ))
                                        .overlay(
                                            isRecentFeedback && context.state.lastFeedbackType == "LIKE" ?
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.rundjMusicGreen, lineWidth: 1)
                                            : nil
                                        )
                                )
                                .scaleEffect(isRecentFeedback && context.state.lastFeedbackType == "LIKE" ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isRecentFeedback && context.state.lastFeedbackType == "LIKE")
                        }
                        .buttonStyle(.plain)
                        
                        // Thumbs down button
                        Button(intent: ThumbsDownIntent()) {
                            Label("Dislike", systemImage: "hand.thumbsdown.fill")
                                .font(.caption)
                                .foregroundColor(.rundjError)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.rundjError.opacity(
                                            isRecentFeedback && context.state.lastFeedbackType == "DISLIKE" ? 0.6 : 0.2
                                        ))
                                        .overlay(
                                            isRecentFeedback && context.state.lastFeedbackType == "DISLIKE" ?
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.rundjError, lineWidth: 1)
                                            : nil
                                        )
                                )
                                .scaleEffect(isRecentFeedback && context.state.lastFeedbackType == "DISLIKE" ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isRecentFeedback && context.state.lastFeedbackType == "DISLIKE")
                        }
                        .buttonStyle(.plain)
                    }
                }
            } compactLeading: {
                // Compact Leading (left side of Dynamic Island)
                Image(systemName: "figure.run")
                    .font(.caption)
                    .foregroundColor(.rundjMusicGreen)
            } compactTrailing: {
                // Compact Trailing (right side of Dynamic Island)
                Text("\(context.state.stepsPerMinute)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.rundjMusicGreen) +
                Text(" SPM")
                    .font(.caption2)
                    .foregroundColor(.rundjTextSecondary)
            } minimal: {
                // Minimal view (when multiple activities are active)
                Image(systemName: "figure.run")
                    .font(.caption)
                    .foregroundColor(.rundjMusicGreen)
            }
            .widgetURL(URL(string: "rundj://activity"))
            .keylineTint(Color.rundjMusicGreen)
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<RunDJActivityAttributes>
    
    // Helper to determine if feedback was recent (within 2 seconds)
    private var isRecentFeedback: Bool {
        guard let feedbackTime = context.state.lastFeedbackTime else { return false }
        return Date().timeIntervalSince(feedbackTime) < 2.0
    }
    
    // Helper to get feedback button appearance
    private func feedbackButtonAppearance(for type: String) -> (color: Color, opacity: Double, scale: Double) {
        if isRecentFeedback && context.state.lastFeedbackType == type {
            return (
                color: type == "LIKE" ? .rundjMusicGreen : .rundjError,
                opacity: 1.0,
                scale: 1.1
            )
        } else {
            return (
                color: type == "LIKE" ? .rundjMusicGreen : .rundjError,
                opacity: 0.2,
                scale: 1.0
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "figure.run")
                        .font(.title3)
                        .foregroundColor(.rundjMusicGreen)
                    Text("RunDJ")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.rundjTextPrimary)
                }
                
                Spacer()
                
                // Timer
                Text(timerInterval: context.attributes.startTime...Date.distantFuture,
                     countsDown: false,
                     showsHours: true)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.rundjTextPrimary)
            }
            
            // Stats Row
            HStack(spacing: 20) {
                // Steps per minute
                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(context.state.stepsPerMinute)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.rundjMusicGreen)
                        Text("SPM")
                            .font(.caption)
                            .foregroundColor(.rundjTextSecondary)
                    }
                    Text("Target: \(context.attributes.targetBPM)")
                        .font(.caption2)
                        .foregroundColor(.rundjTextSecondary)
                }
                
                // Distance
                VStack(spacing: 4) {
                    Text(context.state.distance.formatted(.number.precision(.fractionLength(1))))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.rundjAccent)
                    Text(context.state.useMetricUnits ? "kilometers" : "miles")
                        .font(.caption)
                        .foregroundColor(.rundjTextSecondary)
                }
                
                // Pace
                VStack(spacing: 4) {
                    Text(context.state.pace)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.rundjWarning)
                    Text(context.state.useMetricUnits ? "min/km" : "min/mi")
                        .font(.caption)
                        .foregroundColor(.rundjTextSecondary)
                }
            }
            
            // Now Playing Section
            HStack(spacing: 12) {
                Image(systemName: context.state.isPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.body)
                    .foregroundColor(.rundjMusicGreen)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.currentSong)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.rundjTextPrimary)
                        .lineLimit(1)
                    
                    Text("\(context.state.currentArtist) • \(context.state.songBPM) BPM")
                        .font(.caption)
                        .foregroundColor(.rundjTextSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    let thumbsUpAppearance = feedbackButtonAppearance(for: "LIKE")
                    Button(intent: ThumbsUpIntent()) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.body)
                            .foregroundColor(thumbsUpAppearance.color)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(thumbsUpAppearance.color.opacity(thumbsUpAppearance.opacity))
                                    .overlay(
                                        // Pulsing ring for recent feedback
                                        isRecentFeedback && context.state.lastFeedbackType == "LIKE" ?
                                        Circle()
                                            .stroke(thumbsUpAppearance.color, lineWidth: 2)
                                            .scaleEffect(1.2)
                                            .opacity(0.6)
                                        : nil
                                    )
                            )
                            .scaleEffect(thumbsUpAppearance.scale)
                            .animation(.easeInOut(duration: 0.2), value: isRecentFeedback && context.state.lastFeedbackType == "LIKE")
                    }
                    .buttonStyle(.plain)
                    
                    let thumbsDownAppearance = feedbackButtonAppearance(for: "DISLIKE")
                    Button(intent: ThumbsDownIntent()) {
                        Image(systemName: "hand.thumbsdown.fill")
                            .font(.body)
                            .foregroundColor(thumbsDownAppearance.color)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(thumbsDownAppearance.color.opacity(thumbsDownAppearance.opacity))
                                    .overlay(
                                        // Pulsing ring for recent feedback
                                        isRecentFeedback && context.state.lastFeedbackType == "DISLIKE" ?
                                        Circle()
                                            .stroke(thumbsDownAppearance.color, lineWidth: 2)
                                            .scaleEffect(1.2)
                                            .opacity(0.6)
                                        : nil
                                    )
                            )
                            .scaleEffect(thumbsDownAppearance.scale)
                            .animation(.easeInOut(duration: 0.2), value: isRecentFeedback && context.state.lastFeedbackType == "DISLIKE")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            .background(Color.rundjCardBackground.opacity(0.3))
            .cornerRadius(8)
        }
        .padding()
    }
}

// MARK: - Manager Class

class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published private(set) var currentActivity: Activity<RunDJActivityAttributes>?
    
    // Start a new Live Activity
    func startActivity(targetBPM: Int) async throws {
        // Check if Live Activities are enabled
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LiveActivityError.disabled
        }
        
        let attributes = RunDJActivityAttributes(
            targetBPM: targetBPM,
            startTime: Date(),
            activityType: "Run"
        )
        
        let initialState = RunDJActivityAttributes.ContentState(
            stepsPerMinute: 0,
            distance: 0.0,
            duration: 0,
            pace: "--:--",
            currentSong: "Getting ready...",
            currentArtist: "RunDJ",
            songBPM: targetBPM,
            isPlaying: false,
            elapsedTime: Date(),
            lastFeedbackType: nil,
            lastFeedbackTime: nil
            useMetricUnits: false
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            await MainActor.run {
                currentActivity = activity
            }
        } catch {
            throw LiveActivityError.failedToStart(error)
        }
    }
    
    // Update the Live Activity
    func updateActivity(
        stepsPerMinute: Int,
        distance: Double,
        duration: TimeInterval,
        pace: String,
        currentSong: String,
        currentArtist: String,
        songBPM: Int,
        isPlaying: Bool,
        useMetricUnits: Bool
    ) async {
        guard let activity = currentActivity else { return }
        
        // Check for recent feedback from shared UserDefaults
        var lastFeedbackType: String? = nil
        var lastFeedbackTime: Date? = nil
        
        if let sharedDefaults = UserDefaults(suiteName: "group.com.rundj.RunDJ") {
            lastFeedbackType = sharedDefaults.string(forKey: "lastFeedbackType")
            lastFeedbackTime = sharedDefaults.object(forKey: "lastFeedbackTime") as? Date
            
            // Clear feedback if it's older than 3 seconds
            if let feedbackTime = lastFeedbackTime, Date().timeIntervalSince(feedbackTime) > 3.0 {
                sharedDefaults.removeObject(forKey: "lastFeedbackType")
                sharedDefaults.removeObject(forKey: "lastFeedbackTime")
                lastFeedbackType = nil
                lastFeedbackTime = nil
            }
        }
        
        let updatedState = RunDJActivityAttributes.ContentState(
            stepsPerMinute: stepsPerMinute,
            distance: distance,
            duration: duration,
            pace: pace,
            currentSong: currentSong,
            currentArtist: currentArtist,
            songBPM: songBPM,
            isPlaying: isPlaying,
            elapsedTime: Date(),
            lastFeedbackType: lastFeedbackType,
            lastFeedbackTime: lastFeedbackTime
            useMetricUnits: useMetricUnits
        )
        
        await activity.update(
            ActivityContent(
                state: updatedState,
                staleDate: Date().addingTimeInterval(30)
            )
        )
    }
    
    func endActivity() async {
        guard let activity = currentActivity else { return }
        
        let finalState = RunDJActivityAttributes.ContentState(
            stepsPerMinute: 0,
            distance: 0,
            duration: 0,
            pace: "--:--",
            currentSong: "Run Complete!",
            currentArtist: "Great job!",
            songBPM: 0,
            isPlaying: false,
            elapsedTime: Date(),
            lastFeedbackType: nil,
            lastFeedbackTime: nil
            useMetricUnits: false
        )
        
        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .immediate
        )
        
        await MainActor.run {
            currentActivity = nil
        }
    }
    
    func handleDeepLink(_ url: URL) {
        // Handle feedback URLs: rundj://feedback/thumbsup or rundj://feedback/thumbsdown
        guard let host = url.host, host == "feedback" else { return }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard let action = pathComponents.first else { return }
        
        switch action {
        case "thumbsup":
            NotificationCenter.default.post(name: .liveActivityThumbsUp, object: nil)
        case "thumbsdown":
            NotificationCenter.default.post(name: .liveActivityThumbsDown, object: nil)
        default:
            break
        }
    }
}

// MARK: - Error Types

enum LiveActivityError: LocalizedError {
    case disabled
    case failedToStart(Error)
    
    var errorDescription: String? {
        switch self {
        case .disabled:
            return "Live Activities are disabled. Please enable them in Settings."
        case .failedToStart(let error):
            return "Failed to start Live Activity: \(error.localizedDescription)"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let liveActivityThumbsUp = Notification.Name("liveActivityThumbsUp")
    static let liveActivityThumbsDown = Notification.Name("liveActivityThumbsDown")
    static let liveActivityStopRun = Notification.Name("liveActivityStopRun")
}
