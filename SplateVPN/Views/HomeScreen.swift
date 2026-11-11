import SwiftUI
import SplateCore

public struct HomeScreen: View {
    @ObservedObject var appState: AppState
    @Binding var selectedTab: Int
    @State private var showingServerSheet = false

    public var body: some View {
        ZStack {
            // Ambient Deep Space Background
            SplateTheme.backgroundDark
                .ignoresSafeArea()

            // Subtle Background Glow Behind Power Button
            RadialGradient(
                colors: [
                    ambientGlowColor.opacity(0.18),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 260
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Top Brand Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Splate")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(SplateTheme.textPrimary)

                            Text("VPN")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(SplateTheme.accentCyan)
                        }

                        Text("iOS Engine v\(SplateConstants.version)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(SplateTheme.textTertiary)
                    }

                    Spacer()

                    // Quick Routing Mode Pill
                    Menu {
                        ForEach(RoutingMode.allCases, id: \.self) { mode in
                            Button {
                                appState.routingMode = mode
                                AppGroupStorage.shared.setRoutingMode(mode)
                            } label: {
                                if appState.routingMode == mode {
                                    Label(mode.title, systemImage: "checkmark")
                                } else {
                                    Text(mode.title)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.swap")
                                .font(.system(size: 12, weight: .bold))
                            Text(appState.routingMode == .bypassRu ? "Обход РФ" : appState.routingMode == .global ? "Всё в VPN" : "Белый список")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(SplateTheme.accentCyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(SplateTheme.accentCyan.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(SplateTheme.accentCyan.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                // Hero Connect Button with Status
                VStack(spacing: 18) {
                    HeroConnectButton(status: appState.vpnStatus) {
                        appState.toggleVpn()
                    }

                    VStack(spacing: 6) {
                        Text(appState.vpnStatus.title)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(statusTextColor)

                        if appState.vpnStatus == .connected, let server = appState.activeServer {
                            Text("\(server.protocolType.displayName) • \(server.address):\(server.port)")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(SplateTheme.textSecondary)
                        } else if appState.vpnStatus == .connecting {
                            Text("Установка зашифрованного туннеля...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(SplateTheme.textSecondary)
                        } else {
                            Text("Нажмите для активации защиты")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(SplateTheme.textTertiary)
                        }
                    }
                }

                Spacer()

                // Active Node Card
                Button {
                    showingServerSheet = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(SplateTheme.primaryBlue.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: "server.rack")
                                .font(.system(size: 20))
                                .foregroundColor(SplateTheme.primaryBlue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("ТЕКУЩИЙ УЗЕЛ")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(SplateTheme.textTertiary)

                            Text(appState.activeServer?.name ?? "Выберите сервер")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(SplateTheme.textPrimary)
                                .lineLimit(1)
                        }

                        Spacer()

                        if let ping = appState.activeServer?.ping {
                            LatencyBadge(latency: ping)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SplateTheme.textTertiary)
                    }
                    .padding(16)
                    .glassCard(cornerRadius: 18)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 20)

                // Live Traffic Speeds
                TrafficWidgetView(stats: appState.trafficStats)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showingServerSheet) {
            ServersView(appState: appState)
        }
    }

    private var statusTextColor: Color {
        switch appState.vpnStatus {
        case .connected: return SplateTheme.accentCyan
        case .connecting, .disconnecting: return SplateTheme.accentAmber
        case .failed: return SplateTheme.accentCrimson
        case .disconnected: return SplateTheme.textPrimary
        }
    }

    private var ambientGlowColor: Color {
        switch appState.vpnStatus {
        case .connected: return SplateTheme.accentCyan
        case .connecting, .disconnecting: return SplateTheme.accentAmber
        case .failed: return SplateTheme.accentCrimson
        case .disconnected: return SplateTheme.primaryBlue
        }
    }
}
