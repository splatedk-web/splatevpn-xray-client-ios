import SwiftUI
import SplateCore

public struct SettingsView: View {
    @ObservedObject var appState: AppState

    @State private var antiDpiFragment = true
    @State private var dnsProvider = "Cloudflare (1.1.1.1)"
    @State private var adBlockDns = true

    let dnsOptions = ["Cloudflare (1.1.1.1)", "Google (8.8.8.8)", "AdGuard DNS (Без рекламы)", "Quad9 (9.9.9.9)"]

    public var body: some View {
        NavigationView {
            ZStack {
                SplateTheme.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Routing Mode Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("РЕЖИМ МАРШРУТИЗАЦИИ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(SplateTheme.textTertiary)
                                .padding(.horizontal, 16)

                            VStack(spacing: 0) {
                                ForEach(RoutingMode.allCases, id: \.self) { mode in
                                    Button {
                                        appState.routingMode = mode
                                        AppGroupStorage.shared.setRoutingMode(mode)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(mode.title)
                                                    .font(.system(size: 15, weight: .medium))
                                                    .foregroundColor(SplateTheme.textPrimary)

                                                Text(modeDescription(mode))
                                                    .font(.system(size: 12))
                                                    .foregroundColor(SplateTheme.textSecondary)
                                            }

                                            Spacer()

                                            if appState.routingMode == mode {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(SplateTheme.accentCyan)
                                            }
                                        }
                                        .padding(14)
                                    }

                                    if mode != RoutingMode.allCases.last {
                                        Divider()
                                            .background(SplateTheme.borderSubtle)
                                            .padding(.horizontal, 14)
                                    }
                                }
                            }
                            .glassCard(cornerRadius: 16)
                            .padding(.horizontal, 16)
                        }

                        // DNS & Privacy
                        VStack(alignment: .leading, spacing: 10) {
                            Text("БЕЗОПАСНОСТЬ И DNS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(SplateTheme.textTertiary)
                                .padding(.horizontal, 16)

                            VStack(spacing: 14) {
                                // DNS Provider
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("DNS-резолвер")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(SplateTheme.textPrimary)
                                        Text("Безопасный DNS over HTTPS")
                                            .font(.system(size: 12))
                                            .foregroundColor(SplateTheme.textSecondary)
                                    }

                                    Spacer()

                                    Picker("DNS", selection: $dnsProvider) {
                                        ForEach(dnsOptions, id: \.self) { option in
                                            Text(option).tag(option)
                                        }
                                    }
                                    .tint(SplateTheme.accentCyan)
                                }

                                Divider()
                                    .background(SplateTheme.borderSubtle)

                                // Anti-DPI
                                Toggle(isOn: $antiDpiFragment) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Anti-DPI фрагментация")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(SplateTheme.textPrimary)
                                        Text("Разбиение TLS Client Hello пакетов")
                                            .font(.system(size: 12))
                                            .foregroundColor(SplateTheme.textSecondary)
                                    }
                                }
                                .tint(SplateTheme.accentCyan)

                                Divider()
                                    .background(SplateTheme.borderSubtle)

                                // AdBlock DNS
                                Toggle(isOn: $adBlockDns) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Фильтрация рекламы")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(SplateTheme.textPrimary)
                                        Text("Блокировка трекеров на уровне DNS")
                                            .font(.system(size: 12))
                                            .foregroundColor(SplateTheme.textSecondary)
                                    }
                                }
                                .tint(SplateTheme.accentCyan)
                            }
                            .padding(16)
                            .glassCard(cornerRadius: 16)
                            .padding(.horizontal, 16)
                        }

                        // App Info & Version
                        VStack(alignment: .leading, spacing: 10) {
                            Text("О ПРИЛОЖЕНИИ")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(SplateTheme.textTertiary)
                                .padding(.horizontal, 16)

                            VStack(spacing: 12) {
                                HStack {
                                    Text("Версия сборки")
                                        .font(.system(size: 14))
                                        .foregroundColor(SplateTheme.textSecondary)
                                    Spacer()
                                    Text("SplateVPN \(SplateConstants.version) (iOS)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(SplateTheme.textPrimary)
                                }

                                Divider().background(SplateTheme.borderSubtle)

                                HStack {
                                    Text("Архитектура туннеля")
                                        .font(.system(size: 14))
                                        .foregroundColor(SplateTheme.textSecondary)
                                    Spacer()
                                    Text("XrayCore + HevSocks5")
                                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                                        .foregroundColor(SplateTheme.accentCyan)
                                }

                                Divider().background(SplateTheme.borderSubtle)

                                Link(destination: URL(string: SplateConstants.repositoryUrl)!) {
                                    HStack {
                                        Text("GitHub Репозиторий")
                                            .font(.system(size: 14))
                                            .foregroundColor(SplateTheme.textPrimary)
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(SplateTheme.textTertiary)
                                    }
                                }
                            }
                            .padding(16)
                            .glassCard(cornerRadius: 16)
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func modeDescription(_ mode: RoutingMode) -> String {
        switch mode {
        case .bypassRu:
            return "Российские сервисы и банки открываются напрямую"
        case .global:
            return "Абсолютно весь сетевой трафик идёт через VPN"
        case .directRu:
            return "Через VPN идут только разрешенные зарубежные сайты"
        }
    }
}
