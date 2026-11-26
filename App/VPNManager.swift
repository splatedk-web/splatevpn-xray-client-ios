import Foundation
import NetworkExtension
import SwiftUI
import WidgetKit

@MainActor
final class VPNManager: ObservableObject {
    @Published var state: AppStateSnapshot
    @Published var connectionStatus: NEVPNStatus = .disconnected
    @Published var trafficStats: TrafficStats = .zero
    @Published var rxBytesPerSec: Int64 = 0
    @Published var txBytesPerSec: Int64 = 0
    @Published var lastError: String?
    @Published var isImporting = false
    @Published var isPinging = false

    private var manager: NETunnelProviderManager?
    private var statusObserver: NSObjectProtocol?
    private var statsTask: Task<Void, Never>?
    private var previousStats: TrafficStats = .zero

    var l10n: L10n {
        L10n(code: state.languageCode)
    }

    init() {
        self.state = SharedStateStore.shared.load()
        AssetInstaller.installBundledGeoAssetsIfNeeded()
        AppLogger.shared.log("App launched (servers=\(state.servers.count), lang=\(state.languageCode))", source: "App")
        Task {
            _ = await loadTunnelManager()
        }
    }

    deinit {
        if let statusObserver {
            NotificationCenter.default.removeObserver(statusObserver)
        }
        statsTask?.cancel()
    }

    var isConnected: Bool {
        connectionStatus == .connected
    }

    var isTransitioning: Bool {
        connectionStatus == .connecting || connectionStatus == .disconnecting || connectionStatus == .reasserting
    }

    var statusLabel: String {
        switch connectionStatus {
        case .connected: return l10n.statusConnected
        case .connecting: return l10n.statusConnecting
        case .disconnecting: return l10n.statusDisconnecting
        case .reasserting: return l10n.statusReasserting
        case .invalid: return l10n.statusInvalid
        case .disconnected: return l10n.statusDisconnected
        @unknown default: return l10n.statusDisconnected
        }
    }

    func completeOnboarding() {
        state.hasCompletedOnboarding = true
        try? persistState()
    }

    func resetOnboarding() {
        state.hasCompletedOnboarding = false
        try? persistState()
    }

    func setLanguage(_ code: String) {
        state.languageCode = code
        try? persistState()
    }

    func setThemeKey(_ key: String) {
        state.themeKey = SplateThemeKey.canonical(key).rawValue
        try? persistState()
    }

    func setGlassTransparency(_ value: Double) {
        state.glassTransparency = max(0, min(1, value))
        try? persistState()
    }

    func setGlassBlurEnabled(_ enabled: Bool) {
        state.glassBlurEnabled = enabled
        try? persistState()
    }

    func setUiMode(_ mode: AppUiMode) {
        state.uiMode = mode
        try? persistState()
    }

    func exportEncryptedBackup(password: String) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(state)
        guard let json = String(data: data, encoding: .utf8) else {
            throw CoreBridgeError.invalidPayload("Failed to encode state JSON")
        }
        return try CoreBridge.encryptBackup(plaintextJSON: json, password: password)
    }

    func importEncryptedBackup(document: String, password: String) throws {
        let plain = try CoreBridge.decryptBackup(document: document, password: password)
        guard let data = plain.data(using: .utf8) else {
            throw CoreBridgeError.invalidPayload("Invalid decrypted backup encoding")
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let restored = try decoder.decode(AppStateSnapshot.self, from: data)
        self.state = restored
        try persistState()
        AppLogger.shared.log("Restored backup (servers=\(restored.servers.count))", source: "Backup")
    }

    func loadTunnelManager() async -> Error? {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            if let existing = managers.first(where: {
                ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == AppGroup.tunnelBundleIdentifier
            }) ?? managers.first {
                if let proto = existing.protocolConfiguration as? NETunnelProviderProtocol,
                   proto.providerBundleIdentifier != AppGroup.tunnelBundleIdentifier {
                    proto.providerBundleIdentifier = AppGroup.tunnelBundleIdentifier
                    existing.protocolConfiguration = proto
                    try await existing.saveToPreferences()
                    try await existing.loadFromPreferences()
                }
                self.manager = existing
            } else {
                let created = NETunnelProviderManager()
                let proto = NETunnelProviderProtocol()
                proto.providerBundleIdentifier = AppGroup.tunnelBundleIdentifier
                proto.serverAddress = "SplateVPN"
                created.protocolConfiguration = proto
                created.localizedDescription = "SplateVPN"
                created.isEnabled = true
                try await created.saveToPreferences()
                try await created.loadFromPreferences()
                self.manager = created
            }
            attachStatusObserver()
            syncStatus()
            return nil
        } catch {
            AppLogger.shared.log("loadTunnelManager error: \(error.localizedDescription) (bundle=\(AppGroup.tunnelBundleIdentifier))", source: "App", level: "ERROR")
            return error
        }
    }

    func toggleConnection() async {
        lastError = nil
        if isConnected || connectionStatus == .connecting {
            manager?.connection.stopVPNTunnel()
            stopStatsPolling()
            trafficStats = .zero
            AppLogger.shared.log("User requested disconnect", source: "App")
            return
        }

        guard let selected = state.selectedServer else {
            lastError = l10n.noServerSelected
            return
        }

        do {
            try persistState()
            if manager == nil {
                if let initError = await loadTunnelManager() {
                    let ns = initError as NSError
                    if ns.domain == NEVPNErrorDomain && (ns.code == NEVPNError.configurationReadWriteFailed.rawValue || ns.code == NEVPNError.configurationInvalid.rawValue) {
                        lastError = "Нет права NetworkExtension в сертификате подписи (для VPN нужен сертификат с NetworkExtension или TrollStore). Детали: \(initError.localizedDescription)"
                    } else {
                        lastError = "Не удалось создать VPN-профиль: \(initError.localizedDescription)"
                    }
                    return
                }
            }
            guard let manager else {
                lastError = "Не удалось инициализировать NETunnelProviderManager (\(AppGroup.tunnelBundleIdentifier))"
                return
            }
            if !manager.isEnabled {
                manager.isEnabled = true
                try await manager.saveToPreferences()
                try await manager.loadFromPreferences()
            }
            AppLogger.shared.log("Starting VPN tunnel for \(selected.name)", source: "App")
            try manager.connection.startVPNTunnel()
        } catch {
            lastError = error.localizedDescription
            AppLogger.shared.log("startVPNTunnel error: \(error.localizedDescription)", source: "App", level: "ERROR")
        }
    }

    func selectServer(_ server: ServerProfile) {
        state.selectedServerID = server.id
        try? persistState()
    }

    func deleteServers(at offsets: IndexSet) {
        state.servers.remove(atOffsets: offsets)
        if let selected = state.selectedServerID, !state.servers.contains(where: { $0.id == selected }) {
            state.selectedServerID = state.servers.first?.id
        }
        try? persistState()
    }

    func deleteServer(id: UUID) {
        state.servers.removeAll(where: { $0.id == id })
        if state.selectedServerID == id {
            state.selectedServerID = state.servers.first?.id
        }
        try? persistState()
    }

    func updateServer(_ updated: ServerProfile) {
        guard let idx = state.servers.firstIndex(where: { $0.id == updated.id }) else { return }
        state.servers[idx] = updated
        try? persistState()
    }

    func deleteSubscription(id: UUID) {
        state.subscriptions.removeAll(where: { $0.id == id })
        state.servers.removeAll(where: { $0.subscriptionID == id })
        if let selected = state.selectedServerID, !state.servers.contains(where: { $0.id == selected }) {
            state.selectedServerID = state.servers.first?.id
        }
        try? persistState()
    }

    func updateSettings(_ mutate: (inout TunnelSettings) -> Void) {
        mutate(&state.settings)
        try? persistState()
    }

    func pingAllServers(autoSelectFastest: Bool = false) async {
        guard !state.servers.isEmpty, !isPinging else { return }
        isPinging = true
        defer { isPinging = false }

        let mode = state.settings.pingMode
        AppLogger.shared.log("Pinging \(state.servers.count) servers (mode=\(mode.rawValue))", source: "Ping")
        let results = await ServerPinger.pingAll(servers: state.servers, mode: mode)

        for idx in state.servers.indices {
            state.servers[idx].pingMs = results[state.servers[idx].id]
        }

        if autoSelectFastest,
           let fastest = state.servers.filter({ ($0.pingMs ?? Int.max) > 0 && $0.pingMs != nil })
               .min(by: { ($0.pingMs ?? Int.max) < ($1.pingMs ?? Int.max) }) {
            state.selectedServerID = fastest.id
            AppLogger.shared.log("Auto-selected fastest node: \(fastest.name) (\(fastest.pingMs ?? 0) ms)", source: "Ping")
        }
        try? persistState()
    }

    func importRawInput(_ raw: String) async {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        lastError = nil
        isImporting = true
        defer { isImporting = false }

        do {
            if let resolved = try? CoreBridge.parseSubscriptionLink(trimmed) {
                let fetched = try await SubscriptionService.fetch(from: resolved.url)
                let fallbackHost = URL(string: resolved.url)?.host ?? "Subscription"
                let subName = !resolved.name.isEmpty ? resolved.name : (fetched.title ?? fallbackHost)

                let existingID = state.subscriptions.first(where: { $0.url == resolved.url })?.id ?? UUID()
                let record = SubscriptionRecord(
                    id: existingID,
                    name: subName,
                    url: resolved.url,
                    updatedAt: Date(),
                    uploadBytes: fetched.uploadBytes,
                    downloadBytes: fetched.downloadBytes,
                    totalBytes: fetched.totalBytes,
                    expireTimestamp: fetched.expireTimestamp
                )
                state.subscriptions.removeAll(where: { $0.id == existingID })
                state.subscriptions.append(record)

                let tagged = fetched.profiles.map { item -> ServerProfile in
                    var copy = item
                    copy.subscriptionID = record.id
                    return copy
                }
                state.servers.removeAll(where: { $0.subscriptionID == record.id })
                state.servers.append(contentsOf: tagged)
                if state.selectedServerID == nil {
                    state.selectedServerID = state.servers.first?.id
                }
                try persistState()
                AppLogger.shared.log("Imported subscription '\(subName)': \(tagged.count) servers", source: "Import")
                return
            }

            let imported = try CoreBridge.parseServerSubscription(trimmed)
            guard !imported.isEmpty else {
                lastError = "No valid servers found in input"
                return
            }
            state.servers.append(contentsOf: imported)
            if state.selectedServerID == nil {
                state.selectedServerID = imported.first?.id
            }
            try persistState()
            AppLogger.shared.log("Imported \(imported.count) server(s) from text/QR", source: "Import")
        } catch {
            lastError = error.localizedDescription
            AppLogger.shared.log("Import failed: \(error.localizedDescription)", source: "Import", level: "ERROR")
        }
    }

    func refreshSubscription(_ subscription: SubscriptionRecord) async {
        await importRawInput(subscription.url)
    }

    private func persistState() throws {
        try SharedStateStore.shared.save(state)
    }

    private func attachStatusObserver() {
        if let statusObserver {
            NotificationCenter.default.removeObserver(statusObserver)
        }
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: manager?.connection,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.syncStatus()
            }
        }
    }

    private func syncStatus() {
        connectionStatus = manager?.connection.status ?? .disconnected
        UserDefaults(suiteName: AppGroup.identifier)?.set(connectionStatus == .connected, forKey: "vpn_is_connected")
        WidgetCenter.shared.reloadAllTimelines()
        if connectionStatus == .connected {
            startStatsPolling()
        } else {
            stopStatsPolling()
            if connectionStatus == .disconnected {
                trafficStats = .zero
            }
        }
    }

    private func startStatsPolling() {
        statsTask?.cancel()
        statsTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.fetchTrafficStats()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    private func stopStatsPolling() {
        statsTask?.cancel()
        statsTask = nil
    }

    private func fetchTrafficStats() async {
        guard let session = manager?.connection as? NETunnelProviderSession,
              let payload = try? JSONEncoder().encode(TunnelIPCCommand.trafficStats) else {
            return
        }
        await withCheckedContinuation { continuation in
            do {
                try session.sendProviderMessage(payload) { [weak self] response in
                    defer { continuation.resume() }
                    guard let response,
                          let decoded = try? JSONDecoder().decode(TrafficStats.self, from: response) else {
                        return
                    }
                    Task { @MainActor in
                        guard let self else { return }
                        self.txBytesPerSec = max(0, decoded.uplink - self.previousStats.uplink)
                        self.rxBytesPerSec = max(0, decoded.downlink - self.previousStats.downlink)
                        self.previousStats = decoded
                        self.trafficStats = decoded
                    }
                }
            } catch {
                continuation.resume()
            }
        }
    }
}
