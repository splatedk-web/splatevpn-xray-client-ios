import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var vpn: VPNManager
    @Environment(\.splateColors) private var colors

    @State private var showingQuickPicker = false
    @State private var showingRoutingPicker = false

    private var l10n: L10n { vpn.l10n }

    private var ringColor: Color {
        if vpn.isConnected { return colors.accentConnected }
        if vpn.isTransitioning { return colors.accentAmber }
        return colors.accentCyan
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // 1. Top Egress Location Pill (exact Android layout)
                    EgressLocationCard(isConnected: vpn.isConnected)
                        .padding(.top, 6)

                    // 2. Central Dark Glass Power Button with Concentric Rings
                    Button {
                        Task { await vpn.toggleConnection() }
                    } label: {
                        ZStack {
                            // Outer subtle halo
                            Circle()
                                .stroke(ringColor.opacity(vpn.isConnected ? 0.22 : 0.14), lineWidth: 1.5)
                                .frame(width: 214, height: 214)

                            // Middle thin concentric ring
                            Circle()
                                .stroke(ringColor.opacity(vpn.isConnected ? 0.45 : 0.25), lineWidth: 2)
                                .frame(width: 194, height: 194)

                            // Inner dark glass circle with specular rim
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            ringColor.opacity(vpn.isConnected ? 0.26 : 0.14),
                                            colors.backgroundDeep.opacity(0.92),
                                            Color.black.opacity(0.95)
                                        ],
                                        center: .center,
                                        startRadius: 8,
                                        endRadius: 92
                                    )
                                )
                                .frame(width: 172, height: 172)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [ringColor.opacity(0.75), colors.glassBorderDark],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: ringColor.opacity(vpn.isConnected ? 0.38 : 0.18), radius: 28)

                            VStack(spacing: 12) {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 46, weight: .medium))
                                    .foregroundStyle(ringColor)
                                    .shadow(color: ringColor.opacity(0.55), radius: 12)

                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(ringColor)
                                        .frame(width: 5, height: 5)
                                    Text(vpn.statusLabel.uppercased())
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(1.6)
                                        .foregroundStyle(colors.textPrimary.opacity(0.92))
                                }
                            }
                        }
                    }
                    .buttonStyle(ElasticButtonStyle(targetScale: 0.95))
                    .disabled(vpn.isTransitioning)
                    .padding(.vertical, 8)

                    if let error = vpn.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(colors.accentCrimson)
                            .multilineTextAlignment(.center)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .liquidGlass(cornerRadius: 14, accentBorder: colors.accentCrimson)
                    }

                    // 3. Section Header: "Активный сервер" + "⚡ авто: вкл" pill
                    HStack {
                        Text("Активный сервер")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(colors.textSecondary)
                        Spacer()
                        Button {
                            vpn.updateSettings { $0.autoBalancerEnabled.toggle() }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "bolt.fill")
                                    .font(.caption2)
                                Text(vpn.state.settings.autoBalancerEnabled ? "авто: вкл" : "авто: выкл")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(vpn.state.settings.autoBalancerEnabled ? colors.accentCyan : colors.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .liquidGlass(cornerRadius: 14, accentBorder: vpn.state.settings.autoBalancerEnabled ? colors.accentCyan.opacity(0.45) : nil)
                        }
                        .buttonStyle(ElasticButtonStyle())
                    }

                    // 4. Two Half-Width Glass Cards: "Для чего" & "Подбор по"
                    HStack(spacing: 12) {
                        Menu {
                            ForEach(BalancerGoal.allCases) { goal in
                                Button(goal.titleRu) {
                                    vpn.updateSettings { $0.balancerGoal = goal }
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "target")
                                    .font(.subheadline)
                                    .foregroundStyle(colors.accentCyan)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Для чего")
                                        .font(.caption2)
                                        .foregroundStyle(colors.textSecondary)
                                    Text(vpn.state.settings.balancerGoal.titleRu)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(colors.textPrimary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(colors.textSecondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .liquidGlass(cornerRadius: 18)
                        }

                        Menu {
                            ForEach(BalancerMetric.allCases) { metric in
                                Button(metric.titleRu) {
                                    vpn.updateSettings { $0.balancerMetric = metric }
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "speedometer")
                                    .font(.subheadline)
                                    .foregroundStyle(colors.accentCyan)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Подбор по")
                                        .font(.caption2)
                                        .foregroundStyle(colors.textSecondary)
                                    Text(vpn.state.settings.balancerMetric.titleRu)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(colors.textPrimary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(colors.textSecondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .liquidGlass(cornerRadius: 18)
                        }
                    }

                    // 5. Large Active Server Card (exact Android layout)
                    if let selected = vpn.state.selectedServer {
                        Button {
                            showingQuickPicker = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "server.rack")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(colors.protocolColor(selected.protocolName))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        colors.protocolColor(selected.protocolName).opacity(0.18),
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selected.name)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(colors.textPrimary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    Text("\(selected.protocolName.uppercased()) • \(selected.network.uppercased())")
                                        .font(.caption)
                                        .foregroundStyle(colors.textSecondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                if let ping = selected.pingMs {
                                    Text("\(ping) ms")
                                        .font(.caption.monospacedDigit().weight(.semibold))
                                        .foregroundStyle(pingColor(ping))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(colors.surfaceElevated.opacity(0.7), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(colors.textSecondary)
                            }
                            .padding(16)
                            .liquidGlass(cornerRadius: 22, accentBorder: vpn.isConnected ? colors.accentConnected.opacity(0.55) : nil)
                        }
                        .buttonStyle(ElasticButtonStyle())
                    } else {
                        Text(l10n.noServerSelected)
                            .font(.footnote)
                            .foregroundStyle(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .liquidGlass(cornerRadius: 20)
                    }

                    // 6. Traffic Stats Row when connected
                    if vpn.isConnected {
                        HStack(spacing: 12) {
                            statCard(title: l10n.uploaded, bytes: vpn.trafficStats.uplink, icon: "arrow.up.circle.fill")
                            statCard(title: l10n.downloaded, bytes: vpn.trafficStats.downlink, icon: "arrow.down.circle.fill")
                        }
                    }

                    // 7. Bottom Routing Bar ("Умный маршрут | Изменить >")
                    Button {
                        showingRoutingPicker = true
                    } label: {
                        HStack {
                            Text(l10n.routingTitle(vpn.state.settings.routingMode))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(colors.textPrimary)
                            Spacer()
                            HStack(spacing: 4) {
                                Text("Изменить")
                                    .font(.caption.weight(.semibold))
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundStyle(colors.accentCyan)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .liquidGlass(cornerRadius: 18)
                    }
                    .buttonStyle(ElasticButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingQuickPicker) {
                QuickServerPickerSheet()
            }
            .confirmationDialog("Режим маршрутизации", isPresented: $showingRoutingPicker, titleVisibility: .visible) {
                ForEach(RoutingMode.allCases) { mode in
                    Button(l10n.routingTitle(mode)) {
                        vpn.updateSettings { $0.routingMode = mode }
                    }
                }
                Button(l10n.cancel, role: .cancel) {}
            }
        }
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
        .padding(.vertical, 10)
        .liquidGlass(cornerRadius: 16)
    }
}
