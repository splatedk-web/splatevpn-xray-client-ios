import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vpn: VPNManager
    @Environment(\.splateColors) private var colors
    @State private var selectedTab: AppTab = .home

    private var visibleTabs: [AppTab] {
        AppTab.visibleTabs(for: vpn.state.uiMode)
    }

    private var ambientGlowColor: Color {
        switch vpn.connectionStatus {
        case .connected: return colors.accentConnected
        case .connecting, .reasserting: return colors.accentAmber
        case .invalid: return colors.accentCrimson
        default: return colors.accentCyan
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            GlassBackdropView(accentGlow: ambientGlowColor, isConnected: vpn.isConnected)

            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .servers:
                    ServersView()
                case .rules:
                    NavigationStack {
                        RoutingRulesView()
                    }
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 84)
            }

            FloatingLiquidDock(
                selectedTab: $selectedTab,
                tabs: visibleTabs,
                l10n: vpn.l10n
            )
        }
        .onChange(of: vpn.state.uiMode) { newMode in
            let allowed = AppTab.visibleTabs(for: newMode)
            if !allowed.contains(selectedTab) {
                selectedTab = .home
            }
        }
    }
}
