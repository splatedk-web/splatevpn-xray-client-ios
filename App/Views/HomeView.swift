import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var vpn: VPNManager
    @Environment(\.splateColors) private var colors

    @State private var showingQuickPicker = false
    @State private var showingRoutingPicker = false
    @State private var toolsExpanded = false
    @State private var ringPulse = false

    private var l10n: L10n { vpn.l10n }

    private var ringColor: Color {
        if vpn.isConnected { return colors.accentConnected }
        if vpn.isTransitioning { return colors.accentAmber }
        return colors.accentCyan
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 1. Android Header: Shield icon + SPLATE VPN / Xray version + Routing & Logs buttons
                    HStack(spacing: 12) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(colors.accentCyan)
                            .frame(width: 40, height: 40)
                            .liquidGlass(cornerRadius: 12)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("SPLATE VPN")
                                .font(.system(size: 17, weight: .heavy))
                                .tracking(0.6)
                                .foregroundStyle(colors.textPrimary)
                            Text("Xray \(CoreBridge.coreVersion)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(colors.textSecondary)
                        }

                        Spacer()

                        NavigationLink {
                            RoutingRulesView()
                        } label: {
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(colors.textPrimary)
                                .frame(width: 40, height: 40)
                                .liquidGlass(cornerRadius: 12)
                        }
                        .buttonStyle(ElasticButtonStyle())

                        NavigationLink {
                            LogsView()
                        } label: {
                            Image(systemName: "terminal")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(colors.textPrimary)
                                .frame(width: 40, height: 40)
                                .liquidGlass(cornerRadius: 12)
                        }
                        .buttonStyle(ElasticButtonStyle())
                    }
                    .padding(.top, 4)

                    // 2. Status Pill (when disconnected) or Egress Location Card (when connected)
                    if vpn.isConnected {
                        EgressLocationCard(isConnected: true)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    } else {
                        HStack(spacing: 7) {
                            Circle()
                                .fill(vpn.isTransitioning ? colors.accentAmber : colors.textSecondary)
                                .frame(width: 7, height: 7)
                            Text(vpn.isTransitioning ? vpn.statusLabel : "Ожидание • не защищено")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(colors.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .liquidGlass(cornerRadius: 20)
                    }

                    // 3. Central Dark Glossy Power Button with Animated Concentric Rings
                    Button {
                        Task { await vpn.toggleConnection() }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(ringColor.opacity(vpn.isConnected ? 0.24 : 0.14), lineWidth: 1.2)
                                .frame(width: 212, height: 212)
                                .scaleEffect(ringPulse ? 1.06 : 0.98)

                            Circle()
                                .stroke(ringColor.opacity(vpn.isConnected ? 0.45 : 0.24), lineWidth: 1.8)
                                .frame(width: 190, height: 190)
                                .scaleEffect(ringPulse ? 1.03 : 0.99)

                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            ringColor.opacity(vpn.isConnected ? 0.26 : 0.16),
                                            colors.backgroundDeep.opacity(0.94),
                                            Color.black.opacity(0.96)
                                        ],
                                        center: UnitPoint(x: 0.5, y: 0.28),
                                        startRadius: 6,
                                        endRadius: 94
                                    )
                                )
                                .frame(width: 168, height: 168)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [ringColor.opacity(0.8), colors.glassBorderDark],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: ringColor.opacity(vpn.isConnected ? 0.42 : 0.18), radius: 26)

                            VStack(spacing: 10) {
                                Image(systemName: vpn.isConnected ? "shield.fill" : "power")
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundStyle(ringColor)
                                    .shadow(color: ringColor.opacity(0.5), radius: 10)

                                Text(vpn.isConnected ? "ПОДКЛЮЧЕНО" : (vpn.isTransitioning ? "ПОДКЛЮЧЕНИЕ" : "ПОДКЛЮЧИТЬ"))
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1.4)
                                    .foregroundStyle(colors.textPrimary.opacity(0.92))
                            }
                        }
                    }
                    .buttonStyle(ElasticButtonStyle(targetScale: 0.94))
                    .disabled(vpn.isTransitioning)
                    .padding(.vertical, 6)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                            ringPulse = true
                        }
                    }

                    if let error = vpn.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(colors.accentCrimson)
                            .multilineTextAlignment(.center)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .liquidGlass(cornerRadius: 14, accentBorder: colors.accentCrimson)
                    }

                    // 4. "Активный сервер" + "⚡ авто: вкл"
                    HStack {
                        Text("Активный сервер")
                            .font(.caption.weight(.semibold))
                            .tracking(0.5)
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
                            .liquidGlass(cornerRadius: 12, accentBorder: vpn.state.settings.autoBalancerEnabled ? colors.accentCyan.opacity(0.4) : nil)
                        }
                        .buttonStyle(ElasticButtonStyle())
                    }

                    // 5. Two Half-Width Glass Cards: "Для чего" & "Подбор по"
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {
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
                                .padding(.horizontal, 12)
                                .padding(.vertical, 11)
                                .liquidGlass(cornerRadius: 16)
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
                                .padding(.horizontal, 12)
                                .padding(.vertical, 11)
                                .liquidGlass(cornerRadius: 16)
                            }
                        }

                        Text(vpn.state.settings.balancerGoal == .general ? "Без приоритета сервиса." : "Приоритет: \(vpn.state.settings.balancerGoal.titleRu)")
                            .font(.caption2)
                            .foregroundStyle(colors.textSecondary)
                            .padding(.horizontal, 4)
                    }

                    // 6. Active Server Card
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

                                Text(selected.pingMs.map { "\($0) ms" } ?? "---")
                                    .font(.caption.monospacedDigit().weight(.semibold))
                                    .foregroundStyle(selected.pingMs.map(pingColor) ?? colors.textTertiary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(colors.surfaceElevated.opacity(0.75), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(colors.textSecondary)
                            }
                            .padding(16)
                            .liquidGlass(cornerRadius: 20, accentBorder: vpn.isConnected ? colors.accentConnected.opacity(0.5) : nil)
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

                    // 7. Routing Bar ("Умный маршрут | Изменить >")
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

                    // 8. 3-Column Metrics Card (Пинг | Приём | Отдача — exact Android screenshot)
                    HStack(spacing: 0) {
                        metricColumn(
                            icon: "circle.fill",
                            iconColor: colors.textSecondary,
                            label: "Пинг",
                            value: vpn.state.selectedServer?.pingMs.map { "\($0) ms" } ?? "---"
                        )
                        Divider().frame(height: 30).overlay(colors.borderSubtle)
                        metricColumn(
                            icon: "arrow.down",
                            iconColor: colors.accentCyan,
                            label: "Приём",
                            value: formatSpeed(vpn.rxBytesPerSec)
                        )
                        Divider().frame(height: 30).overlay(colors.borderSubtle)
                        metricColumn(
                            icon: "arrow.up",
                            iconColor: colors.accentViolet,
                            label: "Отдача",
                            value: formatSpeed(vpn.txBytesPerSec)
                        )
                    }
                    .padding(.vertical, 14)
                    .liquidGlass(cornerRadius: 20)

                    // 9. Centered Expandable "Инструменты соединения v"
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            toolsExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(toolsExpanded ? "Скрыть инструменты" : "Инструменты соединения")
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: toolsExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(colors.textPrimary)
                        .padding(.vertical, 6)
                    }

                    if toolsExpanded {
                        VStack(spacing: 10) {
                            if !vpn.isConnected {
                                EgressLocationCard(isConnected: false)
                            }
                            HStack(spacing: 10) {
                                Button {
                                    Task { await vpn.pingAllServers(autoSelectFastest: true) }
                                } label: {
                                    Label(l10n.autoSelectFastest, systemImage: "bolt.horizontal.circle")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(colors.accentCyan)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 11)
                                        .liquidGlass(cornerRadius: 14)
                                }
                                .buttonStyle(ElasticButtonStyle())
                                .disabled(vpn.isPinging || vpn.state.servers.isEmpty)

                                NavigationLink {
                                    DiagnosticsView()
                                } label: {
                                    Label("Speedtest", systemImage: "speedometer")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(colors.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 11)
                                        .liquidGlass(cornerRadius: 14)
                                }
                                .buttonStyle(ElasticButtonStyle())
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
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

    private func metricColumn(icon: String, iconColor: Color, label: String, value: String) -> some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: icon == "circle.fill" ? 6 : 10, weight: .bold))
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(colors.textSecondary)
            }
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatSpeed(_ bytesPerSec: Int64) -> String {
        if bytesPerSec >= 1_048_576 {
            return String(format: "%.1f MB/s", Double(bytesPerSec) / 1_048_576.0)
        }
        return "\(bytesPerSec / 1024) KB/s"
    }

    private func pingColor(_ ms: Int) -> Color {
        if ms < 150 { return colors.accentEmerald }
        if ms < 350 { return colors.accentAmber }
        return colors.accentCrimson
    }
}
