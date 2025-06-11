//
//  DesignSystem.swift
//  RunDJ
//
//  Design system containing colors, styles, and reusable components
//

import SwiftUI

// MARK: - Colors

extension Color {
    // Primary Colors
    static let rundjMusicGreen = Color(hex: "1DB954") // Spotify-inspired green for music elements
    static let rundjPrimary = Color(hex: "2D3748") // Dark slate for primary UI elements
    static let rundjAccent = Color(hex: "4299E1") // Bright blue for accents
    
    // Background Colors
    static let rundjBackground = Color(hex: "0A0E1A") // Very dark blue-black
    static let rundjCardBackground = Color(hex: "111827") // Slightly lighter for cards
    static let rundjSecondaryBackground = Color(hex: "0D1421") // In-between shade
    
    // Text Colors
    static let rundjTextPrimary = Color.white
    static let rundjTextSecondary = Color(white: 0.85)
    static let rundjTextTertiary = Color(white: 0.6)
    
    // Semantic Colors
    static let rundjSuccess = rundjMusicGreen
    static let rundjWarning = Color(hex: "F59E0B")
    static let rundjError = Color(hex: "EF4444")
    static let rundjInfo = rundjAccent
    
    // Support init from hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradients

extension LinearGradient {
    static let rundjMusicGradient = LinearGradient(
        colors: [Color.rundjMusicGreen, Color.rundjMusicGreen.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let rundjPrimaryGradient = LinearGradient(
        colors: [Color.rundjPrimary, Color.rundjPrimary.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let rundjBackgroundGradient = LinearGradient(
        colors: [Color.rundjBackground, Color.rundjSecondaryBackground],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let rundjCardGradient = LinearGradient(
        colors: [Color.rundjCardBackground, Color.rundjCardBackground.opacity(0.95)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - View Modifiers

struct RundjCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.rundjCardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct RundjButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let isDisabled: Bool
    let isMusic: Bool
    
    init(backgroundColor: Color = .rundjPrimary,
         foregroundColor: Color = .white,
         isDisabled: Bool = false,
         isMusic: Bool = false) {
        self.backgroundColor = isMusic ? .rundjMusicGreen : backgroundColor
        self.foregroundColor = foregroundColor
        self.isDisabled = isDisabled
        self.isMusic = isMusic
    }
    
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(isDisabled ? .rundjTextTertiary : foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isDisabled ? Color.rundjCardBackground : backgroundColor)
            )
            .scaleEffect(configuration.isPressed && !isDisabled ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct RundjPrimaryButtonStyle: ButtonStyle {
    let isDisabled: Bool
    let isMusic: Bool
    
    init(isDisabled: Bool = false, isMusic: Bool = false) {
        self.isDisabled = isDisabled
        self.isMusic = isMusic
    }
    
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDisabled ? Color.rundjCardBackground : (isMusic ? Color.rundjMusicGreen : Color.rundjPrimary))
            )
            .shadow(color: isDisabled ? .clear : Color.black.opacity(0.15), 
                    radius: 4, x: 0, y: 2)
            .scaleEffect(configuration.isPressed && !isDisabled ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct RundjIconButtonStyle: ButtonStyle {
    let size: CGFloat
    let color: Color
    let isDisabled: Bool
    let isMusic: Bool
    
    init(size: CGFloat = 44, color: Color = .rundjAccent, isDisabled: Bool = false, isMusic: Bool = false) {
        self.size = size
        self.color = isMusic ? .rundjMusicGreen : color
        self.isDisabled = isDisabled
        self.isMusic = isMusic
    }
    
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.5))
            .foregroundColor(isDisabled ? .rundjTextTertiary : color)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(Color.rundjCardBackground.opacity(0.8))
            )
            .overlay(
                Circle()
                    .stroke(isDisabled ? Color.rundjTextTertiary.opacity(0.2) : color.opacity(0.3), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed && !isDisabled ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Components

struct RundjDivider: View {
    var body: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(Color.rundjTextTertiary.opacity(0.2))
            .padding(.horizontal, 16)
    }
}

struct RundjSectionHeader: View {
    let title: String
    let isMusic: Bool
    
    init(title: String, isMusic: Bool = false) {
        self.title = title
        self.isMusic = isMusic
    }
    
    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(isMusic ? .rundjMusicGreen : .rundjTextPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }
}

struct RundjStatCard: View {
    let title: String
    let value: String
    let icon: String?
    let isMusic: Bool
    
    init(title: String, value: String, icon: String? = nil, isMusic: Bool = false) {
        self.title = title
        self.value = value
        self.icon = icon
        self.isMusic = isMusic
    }
    
    var body: some View {
        VStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isMusic ? .rundjMusicGreen : .rundjAccent)
            }
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.rundjTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isMusic ? .rundjMusicGreen : .rundjTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.rundjCardBackground)
        .cornerRadius(10)
    }
}

// MARK: - Compact Components for iPhone

struct CompactStatView: View {
    let title: String
    let value: String
    let isMusic: Bool
    
    init(title: String, value: String, isMusic: Bool = false) {
        self.title = title
        self.value = value
        self.isMusic = isMusic
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.rundjTextSecondary)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isMusic ? .rundjMusicGreen : .rundjTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - View Extensions

extension View {
    func rundjCard() -> some View {
        modifier(RundjCardStyle())
    }
    
    func rundjBackground() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.rundjBackground)
            .ignoresSafeArea()
    }
}
