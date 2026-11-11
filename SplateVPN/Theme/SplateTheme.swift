import SwiftUI

public enum SplateTheme {
    // Backgrounds
    public static let backgroundDark = Color(hex: "070B14")
    public static let backgroundDeep = Color(hex: "030509")
    public static let surfaceDark = Color(hex: "0F1626")
    public static let surfaceElevated = Color(hex: "151E33")

    // Borders & Glass
    public static let borderSubtle = Color(hex: "1E2B42")
    public static let borderMedium = Color(hex: "2A3B5A")
    public static let glassWhite = Color.white.opacity(0.06)
    public static let glassBorder = Color.white.opacity(0.12)

    // Accents
    public static let primaryBlue = Color(hex: "3B82F6")
    public static let accentCyan = Color(hex: "00F0FF")
    public static let accentEmerald = Color(hex: "10E79D")
    public static let accentCrimson = Color(hex: "FF3366")
    public static let accentAmber = Color(hex: "FFB300")
    public static let accentViolet = Color(hex: "A78BFA")

    // Typography Colors
    public static let textPrimary = Color(hex: "F8FAFC")
    public static let textSecondary = Color(hex: "94A3B8")
    public static let textTertiary = Color(hex: "475569")
}

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

public struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(SplateTheme.surfaceDark.opacity(0.75))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        SplateTheme.glassBorder,
                                        SplateTheme.borderSubtle.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    public func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}
