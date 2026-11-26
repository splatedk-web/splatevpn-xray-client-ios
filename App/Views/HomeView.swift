import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var vpn: VPNManager
    @Environment(\.splateColors) private var colors

    @State private var showingQuickPicker = false
    @State private var toolsExpanded = false

    private var l10n: L10n { vpn.l10n }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Spacer(minLength: 10)

                    Button {
                        Task { await vpn.toggleConnection() }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(
                                    (vpn.isConnected ? colors.accentConnected : colors.accentCyan).opacity(0.28),
                                    lineWidth: 10
                                )
                                .frame(width: 196, height: 196)

                            Circle()
                                .fill(buttonGradient)
                                .frame(width: 172, height: 172)
                                .shadow(
                                    color: (vpn.isConnected ? colors.accentConnected : colors.accentCyan).opacity(0.45),
                                    radius: 26,
                                    y: 8
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(colors.glassBorderLight, lineWidth: 1.5)
                                )

                            VStack(spacing: 8) {
                                Image(systemName: vpn.isConnected ? "power" : "shield.fill")
                                    .font(.system(size: 46, weight: .semibold))
                                Text(vpn.isConnected ? l10n.disconnect : l10n.connect)
                                    .font(.headline)
                            }
                            .foregroundStyle(colors.onAccent)
                        }
                    }
                    .buttonStyle(ElasticButtonStyle(targetScale: 0.94))
                    .disabled(vpn.isTransitioning)
                    .accessibilityLabel(vpn.isConnected ? l10n.disconnect : l10n.connect)

                    Text(vpn.statusLabel)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(vpn.isConnected ? colors.accentConnected : colors.textSecondary)

                    if let selected = vpn.state.selectedServer {
                        Button {
                            showingQuickPicker = true
                        } label: {
                            VStack(spacing: 6) {
                                HStack {
                                    Text(selected.protocolName.uppercased())
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(colors.protocolColor(selected.protocolName).opacity(0.18), in: Capsule())
                                        .foregroundStyle(colors.protocolColor(selected.protocolName))

                                    Text(selected.name)
                                        .font(.headline)
                                        .foregroundStyle(colors.textPrimary)
                                        .lineLimit(1)

                                    Spacer()

                                    if let ping = selected.pingMs {
                                        Text("\(ping) ms")
                                            .font(.caption.monospacedDigit().weight(.semibold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(pingColor(ping).opacity(0.18), in: Capsule())
                                            .foregroundStyle(pingColor(ping))
                                    }

                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(colors.textTertiary)
                                }
                                Text(selected.displaySubtitle)
                                    .font(.caption)
                                    .foregroundStyle(colors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(1)
                            }
                            .padding(16)
                            .liquidGlass(cornerRadius: 20, accentBorder: vpn.isConnected ? colors.accentConnected : nil)
                        }
                        .buttonStyle(ElasticButtonStyle())
                        .padding(.horizontal, 16)
                    } else {
                        Text(l10n.noServerSelected)
                            .font(.footnote)
                            .foregroundStyle(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(16)
                            .liquidGlass(cornerRadius: 18)
                            .padding(.horizontal, 16)
                    }

                    EgressLocationCard(isConnected: vpn.isConnected)
                        .padding(.horizontal, 16)

                    if vpn.isConnected {
                        HStack(spacing: 14) {
                            statCard(title: l10n.uploaded, bytes: vpn.trafficStats.uplink, icon: "arrow.up.circle.fill")
                            statCard(title: l10n.downloaded, bytes: vpn.trafficStats.downlink, icon: "arrow.down.circle.fill")
                        }
                        .padding(.horizontal, 16)
                    }

                    connectionToolsCard
                        .padding(.horizontal, 16)

                    if let error = vpn.lastError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(colors.accentCrimson)
                            .multilineTextAlignment(.center)
                            .padding(12)
                            .liquidGlass(cornerRadius: 14, accentBorder: colors.accentCrimson)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 28)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("SplateVPN")
            .sheet(isPresented: $showingQuickPicker) {
                QuickServerPickerSheet()
            }
        }
    }

    private var connectionToolsCard: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    toolsExpanded.toggle()
                }
            } label: {
                HStack {
                    Label("Инструменты соединения", systemImage: "wrench.and.screwdriver")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(colors.textPrimary)
                    Spacer()
                    Image(systemName: toolsExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(colors.accentCyan)
                }
            }

            if toolsExpanded {
                Divider().overlay(colors.borderSubtle)

                Picker(l10n.routingSection, selection: Binding(
                    get: { vpn.state.settings.routingMode },
                    set: { mode in vpn.updateSettings { $0.routingMode = mode } }
                )) {
                    ForEach(RoutingMode.allCases) { mode in
                        Text(l10n.routingTitle(mode)).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    if vpn.state.servers.count > 1 {
                        Button {
                            Task { await vpn.pingAllServers(autoSelectFastest: true) }
                        } label: {
                            HStack(spacing: 6) {
                                if vpn.isPinging {
                                    ProgressView().controlSize(.small)
                                } else {
                                    Image(systemName: "bolt.horizontal.circle")
                                }
                                Text(l10n.autoSelectFastest)
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(colors.accentCyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .liquidGlass(cornerRadius: 12, accentBorder: colors.accentCyan.opacity(0.45))
                        }
                        .buttonStyle(ElasticButtonStyle())
                        .disabled(vpn.isPinging)
                    }

                    NavigationLink {
                        LogsView()
                    } label: {
                        Label(l10n.logsTitle, systemImage: "doc.text.magnifyingglass")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(colors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .liquidGlass(cornerRadius: 12)
                    }
                    .buttonStyle(ElasticButtonStyle())
                }
            }
        }
        .padding(14)
        .liquidGlass(cornerRadius: 18)
    }

    private var buttonGradient: LinearGradient {
        if vpn.isConnected {
            return LinearGradient(colors: [colors.accentConnected, colors.accentEmerald], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        return LinearGradient(colors: [colors.accentCyan, colors.accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private func pingColor(_ ms: Int) -> Color {
        if ms < 150 { return colors.accentEmerald }
        if ms < 350 { return colors.accentAmber }
        return colors.accentCrimson
    }

    private func statCard(title: String, bytes: Int64, icon: String) -> some View {
        VStack(spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(colors.textSecondary)
            Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .binary))
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 16)
    }
}
