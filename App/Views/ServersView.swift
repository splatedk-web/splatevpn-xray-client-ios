import SwiftUI

private enum ServersSubTab: String, CaseIterable, Identifiable {
    case nodes
    case subscriptions
    case personal

    var id: String { rawValue }

    func title(russian: Bool) -> String {
        switch self {
        case .nodes: return russian ? "Узлы" : "Nodes"
        case .subscriptions: return russian ? "Подписки" : "Subscriptions"
        case .personal: return russian ? "Личные" : "Personal"
        }
    }
}

struct ServersView: View {
    @EnvironmentObject private var vpn: VPNManager
    @Environment(\.splateColors) private var colors

    @State private var subTab: ServersSubTab = .nodes
    @State private var searchQuery = ""
    @State private var showingImportSheet = false
    @State private var showingQRScanner = false
    @State private var shareServer: ServerProfile?
    @State private var editServer: ServerProfile?
    @State private var importText = ""

    private var l10n: L10n { vpn.l10n }
    private var isRussian: Bool { l10n.lang == .ru }

    private var filteredServers: [ServerProfile] {
        let base = subTab == .personal
            ? vpn.state.servers.filter { $0.subscriptionID == nil }
            : vpn.state.servers
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return base }
        return base.filter {
            $0.name.lowercased().contains(q)
                || $0.address.lowercased().contains(q)
                || $0.protocolName.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("", selection: $subTab) {
                    ForEach(ServersSubTab.allCases) { tab in
                        Text(tab.title(russian: isRussian)).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                if subTab != .subscriptions {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(colors.textSecondary)
                        TextField(isRussian ? "Поиск узлов…" : "Search nodes…", text: $searchQuery)
                            .foregroundStyle(colors.textPrimary)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .liquidGlass(cornerRadius: 14)
                    .padding(.horizontal, 16)
                }

                ScrollView {
                    LazyVStack(spacing: 10) {
                        if subTab == .subscriptions {
                            subscriptionsList
                        } else {
                            nodesList
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
            }
            .padding(.top, 6)
            .background(Color.clear)
            .navigationTitle(l10n.tabServers)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        Task { await vpn.pingAllServers() }
                    } label: {
                        if vpn.isPinging {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "speedometer")
                        }
                    }
                    .disabled(vpn.state.servers.isEmpty || vpn.isPinging)

                    Button {
                        showingQRScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                    }

                    Button {
                        showingImportSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
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

    @ViewBuilder
    private var subscriptionsList: some View {
        if vpn.state.subscriptions.isEmpty {
            Text(isRussian ? "Подписок пока нет. Нажмите «+» или отсканируйте QR." : "No subscriptions yet. Tap + or scan QR.")
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
                        VStack(alignment: .leading, spacing: 3) {
                            Text(sub.name)
                                .font(.headline)
                                .foregroundStyle(colors.textPrimary)
                            Text("\(count) \(l10n.nodes.lowercased()) • \(sub.url)")
                                .font(.caption)
                                .foregroundStyle(colors.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button {
                            Task { await vpn.refreshSubscription(sub) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(colors.accentCyan)
                                .padding(8)
                                .background(colors.accentCyan.opacity(0.14), in: Circle())
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
                    Button {
                        editServer = server
                    } label: {
                        Label(isRussian ? "Редактировать" : "Edit", systemImage: "pencil")
                    }
                    if !server.rawLink.isEmpty {
                        Button {
                            shareServer = server
                        } label: {
                            Label("QR / Share", systemImage: "qrcode")
                        }
                        Button {
                            UIPasteboard.general.string = server.rawLink
                        } label: {
                            Label(isRussian ? "Копировать ссылку" : "Copy link", systemImage: "doc.on.doc")
                        }
                    }
                    Button(role: .destructive) {
                        vpn.deleteServer(id: server.id)
                    } label: {
                        Label(isRussian ? "Удалить" : "Delete", systemImage: "trash")
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
                    Button(l10n.pasteClipboard) {
                        importText = paste
                    }
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
