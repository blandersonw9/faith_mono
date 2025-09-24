//
//  StyleGuide.swift
//  faith
//
//  Created by Blake Anderson on 9/24/25.
//

import SwiftUI

struct StyleGuide {
    
    // MARK: - Colors
    
    /// Main brown color: #522F15
    static let mainBrown = Color(hex: "#522F15")
    
    /// Background beige color: #FFFBF7
    static let backgroundBeige = Color(hex: "#FFFBF7")
    
    /// Gold accent color: #D4AF37
    static let gold = Color(hex: "#D4AF37")
    
    // MARK: - Typography
    
    /// Merriweather font family
    static func merriweather(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .custom("Merriweather", size: size)
            .weight(weight)
    }
    
    /// Merriweather italic
    static func merriweatherItalic(size: CGFloat) -> Font {
        return .custom("Merriweather", size: size)
            .italic()
    }
    
    // MARK: - Button Styles
    
    /// Primary button style (brown background)
    static let primaryButton = PrimaryButtonStyle()
    
    /// Secondary button style (white background with brown border)
    static let secondaryButton = SecondaryButtonStyle()
    
    // MARK: - Spacing
    
    static let spacing: Spacing = Spacing()
    
    struct Spacing {
        let xs: CGFloat = 4
        let sm: CGFloat = 8
        let md: CGFloat = 16
        let lg: CGFloat = 24
        let xl: CGFloat = 32
        let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    static let cornerRadius: CornerRadius = CornerRadius()
    
    struct CornerRadius {
        let sm: CGFloat = 8
        let md: CGFloat = 12
        let lg: CGFloat = 16
        let xl: CGFloat = 24
    }
    
    // MARK: - Shadows
    
    static let shadows: Shadows = Shadows()
    
    struct Shadows {
        let sm = Color.black.opacity(0.1)
        let md = Color.black.opacity(0.15)
        let lg = Color.black.opacity(0.2)
    }
}

// MARK: - Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(StyleGuide.merriweather(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, StyleGuide.spacing.md)
            .background(StyleGuide.mainBrown)
            .cornerRadius(StyleGuide.cornerRadius.md)
            .shadow(color: StyleGuide.shadows.sm, radius: 2, x: 0, y: 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(StyleGuide.merriweather(size: 16, weight: .semibold))
            .foregroundColor(StyleGuide.mainBrown)
            .frame(maxWidth: .infinity)
            .padding(.vertical, StyleGuide.spacing.md)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: StyleGuide.cornerRadius.md)
                    .stroke(StyleGuide.mainBrown, lineWidth: 1)
            )
            .cornerRadius(StyleGuide.cornerRadius.md)
            .shadow(color: StyleGuide.shadows.sm, radius: 2, x: 0, y: 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct MinorButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(StyleGuide.merriweather(size: 14, weight: .medium))
            .foregroundColor(StyleGuide.mainBrown)
            .padding(.horizontal, StyleGuide.spacing.md)
            .padding(.vertical, StyleGuide.spacing.sm)
            .background(StyleGuide.backgroundBeige)
            .overlay(
                RoundedRectangle(cornerRadius: StyleGuide.cornerRadius.sm)
                    .stroke(StyleGuide.mainBrown.opacity(0.25), lineWidth: 1)
            )
            .cornerRadius(StyleGuide.cornerRadius.sm)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

// MARK: - Color Extension for Hex Support

extension Color {
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
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply the app's standard background
    func faithBackground() -> some View {
        self.background(StyleGuide.backgroundBeige)
    }
    
    /// Apply primary button style
    func primaryButtonStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    /// Apply secondary button style
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    /// Apply minor button style
    func minorButtonStyle() -> some View {
        self.buttonStyle(MinorButtonStyle())
    }
}
