import SwiftUI

private enum ServersSubTab: String, CaseIterable, Identifiable {
    case nodes
    case subscriptions
    case personal

    var id: String { rawValue }
}

struct ServersView: View {
    @EnvironmentObject private var vpn: VPNManager
    @Environment(\.splateColors) private var colors

    @State private var subTab: ServersSubTab = .nodes
    @State private var sortByPing = false
    @State private var searchQuery = ""
    @State private var showingImportSheet = false
    @State private var showingQRScanner = false
    @State private var shareServer: ServerProfile?
    @State private var editServer: ServerProfile?
    @State private var importText = ""

    private var l10n: L10n { vpn.l10n }
    private var isRussian: Bool { l10n.lang == .ru }

    private var personalCount: Int {
        vpn.state.servers.filter { $0.subscriptionID == nil }.count
    }

    private var filteredServers: [ServerProfile] {
        var base = subTab == .personal
            ? vpn.state.servers.filter { $0.subscriptionID == nil }
            : vpn.state.servers
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            base = base.filter {
                $0.name.lowercased().contains(q)
                    || $0.address.lowercased().contains(q)
                    || $0.protocolName.lowercased().contains(q)
            }
        }
        if sortByPing {
            base.sort { ($0.pingMs ?? Int.max) < ($1.pingMs ?? Int.max) }
        }
        return base
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // 1. Header: "Серверы [N]" + "+" square button
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 10) {
                                Text(l10n.tabServers)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(colors.textPrimary)
                                Text("\(vpn.state.servers.count)")
                                    .font(.caption.monospacedDigit().weight(.bold))
                                    .foregroundStyle(colors.accentCyan)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(colors.accentCyan.opacity(0.15), in: Capsule())
                            }
                            Text("Выбор сервера и проверка задержки")
                                .font(.caption)
                                .foregroundStyle(colors.textSecondary)
                        }
                        Spacer()
                        Button {
                            showingImportSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(colors.accentCyan)
                                .frame(width: 44, height: 44)
                                .liquidGlass(cornerRadius: 14)
                        }
                        .buttonStyle(ElasticButtonStyle())
                    }
                    .padding(.top, 6)

                    // 2. 4-Button Quick Action Bar (Порядок | Авто | REAL/TCP | Проверить — exact Android toolbar)
                    HStack(spacing: 6) {
                        toolbarChip(
                            icon: "line.3.horizontal.decrease",
                            label: "Порядок",
                            tint: sortByPing ? colors.accentAmber : colors.textSecondary,
                            active: sortByPing
                        ) {
                            sortByPing.toggle()
                        }

                        toolbarChip(
                            icon: "bolt.fill",
                            label: "Авто",
                            tint: vpn.state.settings.autoBalancerEnabled ? colors.accentCyan : colors.textSecondary,
                            active: vpn.state.settings.autoBalancerEnabled
                        ) {
                            Task { await vpn.pingAllServers(autoSelectFastest: true) }
                        }

                        toolbarChip(
                            icon: "arrow.left.arrow.right",
                            label: vpn.state.settings.pingMode == .realDelay ? "REAL" : "TCP",
                            tint: colors.accentEmerald,
                            active: true
                        ) {
                            vpn.updateSettings {
                                $0.pingMode = ($0.pingMode == .realDelay) ? .tcp : .realDelay
                            }
                        }

                        toolbarChip(
                            icon: "wifi",
                            label: vpn.isPinging ? "…" : "Проверить",
                            tint: colors.accentCyan,
                            active: vpn.isPinging
                        ) {
                            Task { await vpn.pingAllServers() }
                        }
                    }
                    .padding(5)
                    .liquidGlass(cornerRadius: 18)

                    // 3. Search Bar with inline Clipboard & QR buttons (exact Android layout)
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(colors.textSecondary)
                        TextField("Поиск по имени, IP, протоколу…", text: $searchQuery)
                            .foregroundStyle(colors.textPrimary)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button {
                            if let clip = UIPasteboard.general.string, !clip.isEmpty {
                                Task { await vpn.importRawInput(clip) }
                            }
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                                .foregroundStyle(colors.accentCyan)
                        }
                        Button {
                            showingQRScanner = true
                        } label: {
                            Image(systemName: "qrcode.viewfinder")
                                .foregroundStyle(colors.accentAmber)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .liquidGlass(cornerRadius: 16)

                    // 4. 3-Tab Glass Switch with Counts (Узлы | Подписки | Личные)
                    HStack(spacing: 6) {
                        subTabButton(.nodes, icon: "server.rack", title: "Узлы", count: "\(vpn.state.servers.count)")
                        subTabButton(.subscriptions, icon: "icloud.and.arrow.down", title: "Подписки", count: "\(vpn.state.subscriptions.count)")
                        subTabButton(.personal, icon: "lock.fill", title: "Личные", count: "\(personalCount)")
                    }
                    .padding(4)
                    .liquidGlass(cornerRadius: 18)

                    // 5. Auto-select Banner Card
                    if subTab != .subscriptions, let selected = vpn.state.selectedServer {
                        HStack(spacing: 12) {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(colors.accentCyan)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Автовыбор")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(colors.textPrimary)
                                Text(selected.name)
                                    .font(.caption)
                                    .foregroundStyle(colors.textSecondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button {
                                vpn.updateSettings { $0.autoBalancerEnabled.toggle() }
                            } label: {
                                Text(vpn.state.settings.autoBalancerEnabled ? "Вкл" : "Выкл")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(vpn.state.settings.autoBalancerEnabled ? colors.accentEmerald : colors.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        (vpn.state.settings.autoBalancerEnabled ? colors.accentEmerald : colors.borderMedium).opacity(0.18),
                                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    )
                            }
                        }
                        .padding(14)
                        .liquidGlass(cornerRadius: 18)
                    }

                    // 6. Content List
                    if subTab == .subscriptions {
                        subscriptionsList
                    } else {
                        nodesList
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingQRScanner) {
                QRScannerView { scanned in
                    Task { await vpn.importRawInput(scanned) }
                }
            }
            .sheet(item: $shareServer) { server in
                ServerShareSheet(server: server)
            }
            .sheet(item: $editServer) { server in
                EditServerSheet(server: server) { updated in
                    vpn.updateServer(updated)
                }
            }
            .sheet(isPresented: $showingImportSheet) {
                importSheet
            }
        }
    }

    private func toolbarChip(icon: String, label: String, tint: Color, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                active ? tint.opacity(0.14) : Color.clear,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .buttonStyle(ElasticButtonStyle())
    }

    private func subTabButton(_ tab: ServersSubTab, icon: String, title: String, count: String) -> some View {
        let active = subTab == tab
        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                subTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.caption.weight(.semibold))
                    Text(count).font(.caption2.monospacedDigit()).foregroundStyle(colors.textSecondary)
                }
            }
            .foregroundStyle(active ? colors.accentCyan : colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                active ? colors.accentCyan.opacity(0.16) : Color.clear,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(ElasticButtonStyle())
    }

    @ViewBuilder
    private var subscriptionsList: some View {
        if vpn.state.subscriptions.isEmpty {
            Text(isRussian ? "Подписок пока нет. Нажмите «+» или отсканируйте QR." : "No subscriptions yet.")
                .font(.footnote)
                .foregroundStyle(colors.textSecondary)
                .padding(20)
                .frame(maxWidth: .infinity)
                .liquidGlass(cornerRadius: 18)
        } else {
            ForEach(vpn.state.subscriptions) { sub in
                let count = vpn.state.servers.filter { $0.subscriptionID == sub.id }.count
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundStyle(colors.accentCyan)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(sub.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(colors.textPrimary)
                            Text("Узлы (\(count)) • \(sub.url)")
                                .font(.caption)
                                .foregroundStyle(colors.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button {
                            Task { await vpn.refreshSubscription(sub) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(colors.accentEmerald)
                                .padding(8)
                        }
                        Button(role: .destructive) {
                            vpn.deleteSubscription(id: sub.id)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(colors.accentCrimson)
                                .padding(8)
                        }
                    }
                    if let meta = subscriptionMeta(sub) {
                        Text(meta)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(colors.accentCyan)
                    }
                }
                .padding(14)
                .liquidGlass(cornerRadius: 18)
            }
        }
    }

    @ViewBuilder
    private var nodesList: some View {
        if filteredServers.isEmpty {
            Text(l10n.noServerSelected)
                .font(.footnote)
                .foregroundStyle(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(20)
                .frame(maxWidth: .infinity)
                .liquidGlass(cornerRadius: 18)
        } else {
            ForEach(filteredServers) { server in
                let selected = vpn.state.selectedServer?.id == server.id
                Button {
                    vpn.selectServer(server)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(server.protocolName.uppercased())
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(colors.protocolColor(server.protocolName).opacity(0.18), in: Capsule())
                                    .foregroundStyle(colors.protocolColor(server.protocolName))
                                Text(server.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(colors.textPrimary)
                                    .lineLimit(1)
                            }
                            Text(server.displaySubtitle)
                                .font(.caption)
                                .foregroundStyle(colors.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if let ping = server.pingMs {
                            Text("\(ping) ms")
                                .font(.caption.monospacedDigit().weight(.semibold))
                                .foregroundStyle(ping < 150 ? colors.accentEmerald : (ping < 350 ? colors.accentAmber : colors.accentCrimson))
                        }
                        if selected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(colors.accentCyan)
                        }
                    }
                    .padding(14)
                    .liquidGlass(cornerRadius: 18, accentBorder: selected ? colors.accentCyan : nil)
                }
                .buttonStyle(ElasticButtonStyle())
                .contextMenu {
                    Button { editServer = server } label: {
                        Label("Редактировать", systemImage: "pencil")
                    }
                    if !server.rawLink.isEmpty {
                        Button { shareServer = server } label: {
                            Label("QR / Поделиться", systemImage: "qrcode")
                        }
                        Button { UIPasteboard.general.string = server.rawLink } label: {
                            Label("Копировать ссылку", systemImage: "doc.on.doc")
                        }
                    }
                    Button(role: .destructive) { vpn.deleteServer(id: server.id) } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var importSheet: some View {
        NavigationStack {
            Form {
                Section("VLESS / VMess / Trojan / SS / Hy2 / SOCKS5 / Clash / JSON") {
                    TextEditor(text: $importText)
                        .frame(minHeight: 140)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                if let paste = UIPasteboard.general.string, !paste.isEmpty {
                    Button(l10n.pasteClipboard) { importText = paste }
                }
            }
            .navigationTitle(l10n.importTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l10n.cancel) { showingImportSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(l10n.add) {
                        let raw = importText
                        importText = ""
                        showingImportSheet = false
                        Task { await vpn.importRawInput(raw) }
                    }
                    .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func subscriptionMeta(_ sub: SubscriptionRecord) -> String? {
        var parts: [String] = []
        if let total = sub.totalBytes, total > 0 {
            let used = (sub.uploadBytes ?? 0) + (sub.downloadBytes ?? 0)
            let usedStr = ByteCountFormatter.string(fromByteCount: used, countStyle: .binary)
            let totalStr = ByteCountFormatter.string(fromByteCount: total, countStyle: .binary)
            parts.append("\(usedStr) / \(totalStr)")
        }
        if let exp = sub.expireTimestamp, exp > 0 {
            let date = Date(timeIntervalSince1970: TimeInterval(exp))
            parts.append(date.formatted(date: .abbreviated, time: .omitted))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }
}
