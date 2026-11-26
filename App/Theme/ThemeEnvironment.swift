import SwiftUI

private struct ThemeColorsKey: EnvironmentKey {
    static let defaultValue: AppThemeColors = .dark
}

private struct GlassTransparencyKey: EnvironmentKey {
    static let defaultValue: Double = 0.25
}

private struct GlassBlurEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

public extension EnvironmentValues {
    var splateColors: AppThemeColors {
        get { self[ThemeColorsKey.self] }
        set { self[ThemeColorsKey.self] = newValue }
    }

    var glassTransparency: Double {
        get { self[GlassTransparencyKey.self] }
        set { self[GlassTransparencyKey.self] = newValue }
    }

    var glassBlurEnabled: Bool {
        get { self[GlassBlurEnabledKey.self] }
        set { self[GlassBlurEnabledKey.self] = newValue }
    }
}
