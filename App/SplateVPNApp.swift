import SwiftUI

@main
struct SplateVPNApp: App {
    @StateObject private var vpnManager = VPNManager()

    var body: some Scene {
        WindowGroup {
            ThemedRootContainer()
                .environmentObject(vpnManager)
                .onOpenURL { url in
                    Task {
                        await vpnManager.importRawInput(url.absoluteString)
                    }
                }
        }
    }
}

private struct ThemedRootContainer: View {
    @EnvironmentObject private var vpn: VPNManager
    @Environment(\.colorScheme) private var systemScheme

    var body: some View {
        let colors = AppThemeColors.resolve(themeKey: vpn.state.themeKey, isSystemDark: systemScheme == .dark)
        Group {
            if vpn.state.hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }
        }
        .environment(\.splateColors, colors)
        .environment(\.glassTransparency, vpn.state.glassTransparency)
        .environment(\.glassBlurEnabled, vpn.state.glassBlurEnabled)
        .environment(\.layoutDirection, vpn.l10n.lang.layoutDirection)
        .preferredColorScheme(SplateThemeKey.canonical(vpn.state.themeKey) == .system ? nil : (colors.isDark ? .dark : .light))
        .tint(colors.accentCyan)
    }
}
