import SwiftUI

public enum BackdropStyle: String, Equatable {
    case winter
    case soft
    case stars
    case grid
    case aurora
    case sunset
    case rings
    case pastel
    case ocean
    case sakura
    case pony
    case bloom
}

public enum SplateThemeKey: String, CaseIterable, Identifiable {
    case dark
    case amoled
    case light
    case system
    case cyberpunk
    case winter
    case winterLight = "winter_light"
    case red
    case aurora
    case sunset
    case ocean
    case sakura
    case pony
    case winx

    public var id: String { rawValue }

    public static func canonical(_ raw: String) -> SplateThemeKey {
        let lower = raw.lowercased()
        if lower == "oneplus" { return .red }
        return SplateThemeKey(rawValue: lower) ?? .dark
    }

    public func title(lang: AppLanguage) -> String {
        let ru = lang == .ru
        switch self {
        case .dark: return ru ? "Тёмная" : "Dark"
        case .amoled: return "AMOLED"
        case .light: return ru ? "Светлая" : "Light"
        case .system: return ru ? "Системная" : "System"
        case .cyberpunk: return ru ? "Киберпанк" : "Cyberpunk"
        case .winter: return ru ? "Зима" : "Winter"
        case .winterLight: return ru ? "Зима (светлая)" : "Winter Light"
        case .red: return ru ? "Красная" : "Red"
        case .aurora: return ru ? "Сияние" : "Aurora"
        case .sunset: return ru ? "Закат" : "Sunset"
        case .ocean: return ru ? "Океан" : "Ocean"
        case .sakura: return ru ? "Сакура" : "Sakura"
        case .pony: return "Pony"
        case .winx: return "Winx"
        }
    }
}

public struct AppThemeColors: Equatable {
    public let background: Color
    public let backgroundDeep: Color
    public let surface: Color
    public let surfaceElevated: Color
    public let borderSubtle: Color
    public let borderMedium: Color
    public let textPrimary: Color
    public let textSecondary: Color
    public let textTertiary: Color
    public let accentCyan: Color
    public let accentEmerald: Color
    public let accentAmber: Color
    public let accentCrimson: Color
    public let accentViolet: Color
    public let accentBlue: Color
    public let glassSurface: Color
    public let glassSurfaceElevated: Color
    public let glassBorderLight: Color
    public let glassBorderDark: Color
    public let glassSpecular: Color
    public let onAccent: Color
    public let accentSecondary: Color
    public let ambientB: Color
    public let ambientC: Color
    public let ambientIntensity: Double
    public let backdrop: BackdropStyle
    public let isDark: Bool
    public let accentConnected: Color
    public let glassAlpha: Double

    public static func build(
        isDark: Bool,
        background: UInt32,
        backgroundDeep: UInt32,
        surface: UInt32,
        surfaceElevated: UInt32,
        borderSubtle: UInt32,
        borderMedium: UInt32,
        textPrimary: UInt32,
        textSecondary: UInt32,
        textTertiary: UInt32,
        accent: UInt32,
        accentSecondary: UInt32,
        accentEmerald: UInt32,
        accentAmber: UInt32,
        accentCrimson: UInt32,
        accentViolet: UInt32,
        accentBlue: UInt32,
        onAccent: UInt32,
        ambientB: UInt32,
        ambientC: UInt32,
        ambientIntensity: Double,
        backdrop: BackdropStyle,
        glassAlpha: Double,
        glassBorderLight: UInt32,
        glassBorderDark: UInt32,
        glassSpecular: UInt32,
        accentConnected: UInt32? = nil
    ) -> AppThemeColors {
        let surf = Color(argb: surface)
        let surfEl = Color(argb: surfaceElevated)
        let acc = Color(argb: accent)
        return AppThemeColors(
            background: Color(argb: background),
            backgroundDeep: Color(argb: backgroundDeep),
            surface: surf,
            surfaceElevated: surfEl,
            borderSubtle: Color(argb: borderSubtle),
            borderMedium: Color(argb: borderMedium),
            textPrimary: Color(argb: textPrimary),
            textSecondary: Color(argb: textSecondary),
            textTertiary: Color(argb: textTertiary),
            accentCyan: acc,
            accentEmerald: Color(argb: accentEmerald),
            accentAmber: Color(argb: accentAmber),
            accentCrimson: Color(argb: accentCrimson),
            accentViolet: Color(argb: accentViolet),
            accentBlue: Color(argb: accentBlue),
            glassSurface: surf.opacity(glassAlpha),
            glassSurfaceElevated: surfEl.opacity(min(glassAlpha + 0.08, 0.96)),
            glassBorderLight: Color(argb: glassBorderLight),
            glassBorderDark: Color(argb: glassBorderDark),
            glassSpecular: Color(argb: glassSpecular),
            onAccent: Color(argb: onAccent),
            accentSecondary: Color(argb: accentSecondary),
            ambientB: Color(argb: ambientB),
            ambientC: Color(argb: ambientC),
            ambientIntensity: ambientIntensity,
            backdrop: backdrop,
            isDark: isDark,
            accentConnected: accentConnected.map { Color(argb: $0) } ?? acc,
            glassAlpha: glassAlpha
        )
    }

    public static func resolve(themeKey: String, isSystemDark: Bool) -> AppThemeColors {
        switch SplateThemeKey.canonical(themeKey) {
        case .amoled: return .amoled
        case .light: return .light
        case .cyberpunk: return .cyberpunk
        case .winter: return .winter
        case .winterLight: return .winterLight
        case .red: return .red
        case .aurora: return .aurora
        case .sunset: return .sunset
        case .ocean: return .ocean
        case .sakura: return .sakura
        case .pony: return .pony
        case .winx: return .winx
        case .system: return isSystemDark ? .dark : .light
        case .dark: return .dark
        }
    }

    public func protocolColor(_ proto: String) -> Color {
        let p = proto.lowercased()
        if !isDark {
            switch p {
            case "vless": return accentViolet
            case "vmess", "tuic": return accentBlue
            case "trojan", "wireguard", "wg": return accentEmerald
            case "shadowsocks", "ss": return accentAmber
            case "hysteria", "hysteria2", "hy2": return accentCrimson
            default: return accentCyan
            }
        }
        switch p {
        case "vless": return Color(argb: 0xFFA78BFA)
        case "vmess": return Color(argb: 0xFF00E5FF)
        case "trojan": return Color(argb: 0xFF10E79D)
        case "shadowsocks", "ss": return Color(argb: 0xFFFFB300)
        case "hysteria", "hysteria2", "hy2": return Color(argb: 0xFFFF3366)
        case "tuic": return Color(argb: 0xFF38BDF8)
        case "wireguard", "wg": return Color(argb: 0xFF34D399)
        default: return Color(argb: 0xFF00F0FF)
        }
    }
}

public extension Color {
    init(argb: UInt32) {
        let a = Double((argb >> 24) & 0xFF) / 255.0
        let r = Double((argb >> 16) & 0xFF) / 255.0
        let g = Double((argb >> 8) & 0xFF) / 255.0
        let b = Double(argb & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
