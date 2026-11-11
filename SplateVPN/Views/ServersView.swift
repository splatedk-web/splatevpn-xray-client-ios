import SwiftUI
import SplateCore

public struct ServersView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var searchQuery: String = ""
    @State private var showingAddLinkAlert: Bool = false
    @State private var newLinkText: String = ""
    @State private var showingQrScanner: Bool = false

    public var filteredServers: [ServerNode] {
        if searchQuery.isEmpty {
            return appState.servers
        }
        return appState.servers.filter {
            $0.name.localizedCaseInsensitiveContains(searchQuery) ||
            $0.address.localizedCaseInsensitiveContains(searchQuery) ||
            $0.subName.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    public var body: some View {
        NavigationView {
            ZStack {
                SplateTheme.backgroundDark
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(SplateTheme.textTertiary)

                        TextField("Поиск сервера по имени или IP...", text: $searchQuery)
                            .foregroundColor(SplateTheme.textPrimary)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(SplateTheme.textTertiary)
                            }
                        }
                    }
                    .padding(12)
                    .glassCard(cornerRadius: 14)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Action Controls: Ping All & Add Server
                    HStack {
                        Button {
                            appState.pingAllServers()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.horizontal.circle")
                                Text("Проверить пинг")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(SplateTheme.accentCyan)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(SplateTheme.accentCyan.opacity(0.1))
                            .clipShape(Capsule())
                        }

                        Spacer()

                        // Add options Menu
                        Menu {
                            Button {
                                showingAddLinkAlert = true
                            } label: {
                                Label("Вставить ссылку (VLESS/VMess)", systemImage: "doc.on.clipboard")
                            }

                            Button {
                                showingQrScanner = true
                            } label: {
                                Label("Сканировать QR-код", systemImage: "qrcode.viewfinder")
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                Text("Добавить")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(SplateTheme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(SplateTheme.primaryBlue)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 16)

                    // Servers List
                    if filteredServers.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "server.rack")
                                .font(.system(size: 48))
                                .foregroundColor(SplateTheme.textTertiary)

                            Text(searchQuery.isEmpty ? "Список серверов пуст" : "Ничего не найдено")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(SplateTheme.textSecondary)

                            Text("Добавьте сервер по ссылке или обновите подписку")
                                .font(.system(size: 13))
                                .foregroundColor(SplateTheme.textTertiary)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredServers) { server in
                                ServerRowView(server: server, isSelected: appState.activeServer?.id == server.id) {
                                    appState.selectServer(server)
                                    dismiss()
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let server = filteredServers[index]
                                    if let actualIndex = appState.servers.firstIndex(where: { $0.id == server.id }) {
                                        appState.deleteServer(at: IndexSet(integer: actualIndex))
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Узлы подключения")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(SplateTheme.accentCyan)
                }
            }
            .alert("Добавить сервер", isPresented: $showingAddLinkAlert) {
                TextField("vless://, vmess://, trojan://", text: $newLinkText)
                Button("Добавить") {
                    if appState.addServerFromLink(newLinkText) {
                        newLinkText = ""
                    } else {
                        appState.errorMessage = "Неверный формат ссылки конфигурации"
                    }
                }
                Button("Отмена", role: .cancel) {
                    newLinkText = ""
                }
            } message: {
                Text("Вставьте ссылку конфигурации сервера из буфера обмена.")
            }
            .sheet(isPresented: $showingQrScanner) {
                QrScannerView { scannedText in
                    _ = appState.addServerFromLink(scannedText)
                }
            }
        }
    }
}

public struct ServerRowView: View {
    public let server: ServerNode
    public let isSelected: Bool
    public let onSelect: () -> Void

    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Radio indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? SplateTheme.accentCyan : SplateTheme.textTertiary)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(server.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(SplateTheme.textPrimary)
                            .lineLimit(1)

                        Text(server.protocolType.displayName)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(SplateTheme.primaryBlue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(SplateTheme.primaryBlue.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Text("\(server.address):\(server.port)" + (server.subName.isEmpty ? "" : " • \(server.subName)"))
                        .font(.system(size: 12))
                        .foregroundColor(SplateTheme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                LatencyBadge(latency: server.ping)
            }
            .padding(14)
            .glassCard(cornerRadius: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? SplateTheme.accentCyan.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
