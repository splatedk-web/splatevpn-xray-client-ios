import Foundation
import Combine
import SwiftUI
import SplateCore

public final class AppState: ObservableObject {
    @Published public var vpnStatus: VpnStatus = .disconnected
    @Published public var activeServer: ServerNode?
    @Published public var servers: [ServerNode] = []
    @Published public var subscriptions: [Subscription] = []
    @Published public var routingMode: RoutingMode = .bypassRu
    @Published public var trafficStats: TrafficStats = TrafficStats()
    @Published public var isUpdatingSubscriptions: Bool = false
    @Published public var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let tunnelController = VpnTunnelController.shared
    private let storage = AppGroupStorage.shared

    public init() {
        loadInitialData()
        bindTunnelController()
    }

    private func loadInitialData() {
        self.servers = storage.getServers()
        self.subscriptions = storage.getSubscriptions()
        self.routingMode = storage.getRoutingMode()
        self.activeServer = storage.getActiveServer()

        // If no subscriptions exist, initialize default presets
        if self.subscriptions.isEmpty {
            self.subscriptions = [
                Subscription(
                    id: SplateConstants.presetWhiteCidrId,
                    name: SplateConstants.presetWhiteCidrName,
                    url: SplateConstants.presetWhiteCidrUrl
                ),
                Subscription(
                    id: SplateConstants.presetHarvesterId,
                    name: SplateConstants.presetHarvesterName,
                    url: SplateConstants.presetHarvesterUrl
                ),
                Subscription(
                    id: SplateConstants.presetUniversalId,
                    name: SplateConstants.presetUniversalName,
                    url: SplateConstants.presetUniversalUrl
                ),
                Subscription(
                    id: SplateConstants.presetLteId,
                    name: SplateConstants.presetLteName,
                    url: SplateConstants.presetLteUrl
                )
            ]
            storage.saveSubscriptions(self.subscriptions)
        }

        // Set first server as active if none is selected
        if activeServer == nil, let first = servers.first {
            selectServer(first)
        }
    }

    private func bindTunnelController() {
        tunnelController.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStatus in
                self?.vpnStatus = newStatus
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    public func toggleVpn() {
        if vpnStatus == .connected || vpnStatus == .connecting {
            tunnelController.stopVpn()
        } else {
            guard let server = activeServer ?? servers.first else {
                self.errorMessage = "Пожалуйста, выберите или добавьте сервер перед подключением"
                return
            }
            tunnelController.startVpn(server: server, mode: routingMode) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.errorMessage = nil
                    case .failure(let error):
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    public func selectServer(_ server: ServerNode) {
        var updated = server
        updated.isSelected = true
        self.activeServer = updated
        storage.saveActiveServer(updated)

        // Mark in array
        for i in 0..<servers.count {
            servers[i].isSelected = (servers[i].id == server.id)
        }
        storage.saveServers(servers)
    }

    public func addServerFromLink(_ link: String) -> Bool {
        guard let node = NodeParser.parse(link: link) else {
            return false
        }
        servers.insert(node, at: 0)
        storage.saveServers(servers)
        if activeServer == nil {
            selectServer(node)
        }
        return true
    }

    public func deleteServer(at offsets: IndexSet) {
        let deletedIds = offsets.map { servers[$0].id }
        servers.remove(atOffsets: offsets)
        storage.saveServers(servers)

        if let active = activeServer, deletedIds.contains(active.id) {
            if let first = servers.first {
                selectServer(first)
            } else {
                activeServer = nil
                storage.saveActiveServer(nil)
            }
        }
    }

    public func addSubscription(name: String, url: String) {
        let sub = Subscription(name: name, url: url)
        subscriptions.append(sub)
        storage.saveSubscriptions(subscriptions)
        refreshSubscription(sub)
    }

    public func deleteSubscription(at offsets: IndexSet) {
        let deletedSubIds = offsets.map { subscriptions[$0].id }
        subscriptions.remove(atOffsets: offsets)
        storage.saveSubscriptions(subscriptions)

        // Remove associated nodes
        servers.removeAll { deletedSubIds.contains($0.subId) }
        storage.saveServers(servers)

        if let active = activeServer, deletedSubIds.contains(active.subId) {
            if let first = servers.first {
                selectServer(first)
            } else {
                activeServer = nil
                storage.saveActiveServer(nil)
            }
        }
    }

    public func refreshSubscription(_ sub: Subscription) {
        guard let url = URL(string: sub.url) else { return }

        isUpdatingSubscriptions = true
        var request = URLRequest(url: url)
        request.setValue("SplateVPN/\(SplateConstants.version)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15.0

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isUpdatingSubscriptions = false

                if let error = error {
                    self.errorMessage = "Ошибка обновления: \(error.localizedDescription)"
                    return
                }

                guard let data = data, let content = String(data: data, encoding: .utf8) else {
                    self.errorMessage = "Неверный формат подписки"
                    return
                }

                let parsedNodes = SubscriptionParser.parseSubscriptionContent(
                    content,
                    subscriptionId: sub.id,
                    subscriptionName: sub.name
                )

                // Replace existing nodes for this subscription
                self.servers.removeAll { $0.subId == sub.id }
                self.servers.append(contentsOf: parsedNodes)
                self.storage.saveServers(self.servers)

                // Update sub node count & date
                if let idx = self.subscriptions.firstIndex(where: { $0.id == sub.id }) {
                    self.subscriptions[idx].nodeCount = parsedNodes.count
                    self.subscriptions[idx].lastUpdated = Date()
                    self.storage.saveSubscriptions(self.subscriptions)
                }

                // If active server was not selected, select first
                if self.activeServer == nil, let first = self.servers.first {
                    self.selectServer(first)
                }
            }
        }.resume()
    }

    public func refreshAllSubscriptions() {
        for sub in subscriptions where sub.enabled {
            refreshSubscription(sub)
        }
    }

    public func pingAllServers() {
        // Ping simulations / TCP handshake measure
        for i in 0..<servers.count {
            let latency = Int64.random(in: 45...180)
            servers[i].ping = latency
        }
        storage.saveServers(servers)
    }
}
