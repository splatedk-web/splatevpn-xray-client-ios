import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var vpn: VPNManager
    @Environment(\.splateColors) private var colors
    @State private var searchQuery = ""

    private var isRussian: Bool { vpn.l10n.lang == .ru }
    private var visibleCategories: [SettingsCategory] {
        SettingsCategory.visible(for: vpn.state.uiMode).filter { $0.matches(query: searchQuery) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vpn.l10n.tabSettings)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(colors.textPrimary)
                        Text(isRussian ? "Конфигурация обхода блокировок, оформления и ядра" : "Anti-DPI, appearance and Xray core configuration")
                            .font(.caption)
                            .foregroundStyle(colors.textSecondary)
                    }
                    .padding(.top, 6)

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(colors.textSecondary)
                        TextField(isRussian ? "Найти настройку…" : "Search settings…", text: $searchQuery)
                            .foregroundStyle(colors.textPrimary)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(colors.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .liquidGlass(cornerRadius: 16)

                    ForEach(SettingsGroup.allCases) { group in
                        let items = visibleCategories.filter { $0.group == group }
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(group.title(russian: isRussian).uppercased())
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(colors.textSecondary)
                                    .padding(.horizontal, 6)

                                VStack(spacing: 8) {
                                    ForEach(items) { category in
                                        NavigationLink {
                                            categoryDestination(category)
                                        } label: {
                                            HStack(spacing: 14) {
                                                Image(systemName: category.systemImage)
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundStyle(colors.accentCyan)
                                                    .frame(width: 36, height: 36)
                                                    .background(colors.accentCyan.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(category.title(russian: isRussian))
                                                        .font(.subheadline.weight(.semibold))
                                                        .foregroundStyle(colors.textPrimary)
                                                    Text(category.hint(russian: isRussian))
                                                        .font(.caption)
                                                        .foregroundStyle(colors.textSecondary)
                                                        .lineLimit(2)
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(colors.textTertiary)
                                            }
                                            .padding(14)
                                            .liquidGlass(cornerRadius: 18)
                                        }
                                        .buttonStyle(ElasticButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    private func categoryDestination(_ category: SettingsCategory) -> some View {
        switch category {
        case .appearance:
            ThemePickerView()
        case .routing:
            RoutingRulesView()
        case .backup:
            BackupView()
        case .diagnostics:
            DiagnosticsView()
        case .ai:
            AiSmartDnsView()
        case .sharing:
            SharingView()
        case .sync:
            SyncView()
        case .connection:
            connectionDetail
        case .protection:
            protectionDetail
        case .network:
            networkDetail
        case .advanced:
            advancedDetail
        case .about:
            aboutDetail
        case .tor:
            plannedCategoryDetail(category)
        }
    }

    private var connectionDetail: some View {
        Form {
            Section(vpn.l10n.networkDnsSection) {
                Picker("Ping", selection: Binding(
                    get: { vpn.state.settings.pingMode },
                    set: { mode in vpn.updateSettings { $0.pingMode = mode } }
                )) {
                    ForEach(PingMode.allCases) { mode in
                        Text(vpn.l10n.pingModeTitle(mode)).tag(mode)
                    }
                }
            }
            Section(vpn.l10n.appearanceSection) {
                Picker(vpn.l10n.language, selection: Binding(
                    get: { vpn.state.languageCode },
                    set: { vpn.setLanguage($0) }
                )) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang.rawValue)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(SettingsCategory.connection.title(russian: isRussian))
    }

    private var protectionDetail: some View {
        Form {
            Toggle(vpn.l10n.adBlocker, isOn: Binding(
                get: { vpn.state.settings.enableAdBlock },
                set: { v in vpn.updateSettings { $0.enableAdBlock = v } }
            ))
            Toggle("Block QUIC (UDP 443)", isOn: Binding(
                get: { vpn.state.settings.blockQuic },
                set: { v in vpn.updateSettings { $0.blockQuic = v } }
            ))
            Toggle(vpn.l10n.enableIpv6, isOn: Binding(
                get: { vpn.state.settings.enableIpv6 },
                set: { v in vpn.updateSettings { $0.enableIpv6 = v } }
            ))
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(SettingsCategory.protection.title(russian: isRussian))
    }

    private var networkDetail: some View {
        Form {
            Picker(vpn.l10n.routingSection, selection: Binding(
                get: { vpn.state.settings.routingMode },
                set: { mode in vpn.updateSettings { $0.routingMode = mode } }
            )) {
                ForEach(RoutingMode.allCases) { mode in
                    Text(vpn.l10n.routingTitle(mode)).tag(mode)
                }
            }
            TextField("DNS (IP / DoH)", text: Binding(
                get: { vpn.state.settings.dnsServer },
                set: { value in vpn.updateSettings { $0.dnsServer = value } }
            ))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(SettingsCategory.network.title(russian: isRussian))
    }

    private var advancedDetail: some View {
        Form {
            Toggle(vpn.l10n.tlsFragment, isOn: Binding(
                get: { vpn.state.settings.enableTlsFragment },
                set: { v in vpn.updateSettings { $0.enableTlsFragment = v } }
            ))
            Toggle("Sniffing (HTTP/TLS/QUIC)", isOn: Binding(
                get: { vpn.state.settings.sniffing },
                set: { v in vpn.updateSettings { $0.sniffing = v } }
            ))
            Stepper("MTU: \(vpn.state.settings.mtu)", value: Binding(
                get: { vpn.state.settings.mtu },
                set: { value in vpn.updateSettings { $0.mtu = value } }
            ), in: 1280...1500, step: 20)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(SettingsCategory.advanced.title(russian: isRussian))
    }

    private var aboutDetail: some View {
        Form {
            LabeledContent(vpn.l10n.coreVersion, value: CoreBridge.coreVersion)
            LabeledContent("GeoIP / GeoSite", value: AssetInstaller.hasGeoAssetsInstalled ? "OK" : "—")
            Button(isRussian ? "Показать онбординг снова" : "Replay onboarding") {
                vpn.resetOnboarding()
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(SettingsCategory.about.title(russian: isRussian))
    }

    private func plannedCategoryDetail(_ category: SettingsCategory) -> some View {
        VStack(spacing: 16) {
            Image(systemName: category.systemImage)
                .font(.system(size: 44))
                .foregroundStyle(colors.accentCyan)
            Text(category.title(russian: isRussian))
                .font(.title3.bold())
                .foregroundStyle(colors.textPrimary)
            Text(category.hint(russian: isRussian))
                .font(.subheadline)
                .foregroundStyle(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(category.title(russian: isRussian))
    }
}
