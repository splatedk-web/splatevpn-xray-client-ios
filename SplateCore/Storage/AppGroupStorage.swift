import Foundation

public final class AppGroupStorage {
    public static let shared = AppGroupStorage()

    private let defaults: UserDefaults?

    private enum Keys {
        static let activeServerNode = "active_server_node"
        static let vpnStatus = "vpn_status"
        static let routingMode = "routing_mode"
        static let trafficStats = "traffic_stats"
        static let antiDpiEnabled = "anti_dpi_enabled"
        static let customDns = "custom_dns"
        static let savedServers = "saved_servers"
        static let savedSubscriptions = "saved_subscriptions"
    }

    private init() {
        self.defaults = UserDefaults(suiteName: SplateConstants.appGroupId)
    }

    // MARK: - Active Node & VPN State

    public func saveActiveServer(_ server: ServerNode?) {
        guard let server = server else {
            defaults?.removeObject(forKey: Keys.activeServerNode)
            return
        }
        if let encoded = try? JSONEncoder().encode(server) {
            defaults?.set(encoded, forKey: Keys.activeServerNode)
        }
    }

    public func getActiveServer() -> ServerNode? {
        guard let data = defaults?.data(forKey: Keys.activeServerNode) else { return nil }
        return try? JSONDecoder().decode(ServerNode.self, from: data)
    }

    public func setVpnStatus(_ status: VpnStatus) {
        defaults?.set(status.rawValue, forKey: Keys.vpnStatus)
    }

    public func getVpnStatus() -> VpnStatus {
        guard let raw = defaults?.string(forKey: Keys.vpnStatus),
              let status = VpnStatus(rawValue: raw) else {
            return .disconnected
        }
        return status
    }

    public func setRoutingMode(_ mode: RoutingMode) {
        defaults?.set(mode.rawValue, forKey: Keys.routingMode)
    }

    public func getRoutingMode() -> RoutingMode {
        guard let raw = defaults?.string(forKey: Keys.routingMode),
              let mode = RoutingMode(rawValue: raw) else {
            return .bypassRu
        }
        return mode
    }

    public func saveTrafficStats(_ stats: TrafficStats) {
        if let data = try? JSONEncoder().encode(stats) {
            defaults?.set(data, forKey: Keys.trafficStats)
        }
    }

    public func getTrafficStats() -> TrafficStats {
        guard let data = defaults?.data(forKey: Keys.trafficStats),
              let stats = try? JSONDecoder().decode(TrafficStats.self, from: data) else {
            return TrafficStats()
        }
        return stats
    }

    // MARK: - Servers Persistence

    public func saveServers(_ servers: [ServerNode]) {
        if let data = try? JSONEncoder().encode(servers) {
            defaults?.set(data, forKey: Keys.savedServers)
        }
    }

    public func getServers() -> [ServerNode] {
        guard let data = defaults?.data(forKey: Keys.savedServers),
              let list = try? JSONDecoder().decode([ServerNode].self, from: data) else {
            return []
        }
        return list
    }

    // MARK: - Subscriptions Persistence

    public func saveSubscriptions(_ subs: [VpnSubscription]) {
        if let data = try? JSONEncoder().encode(subs) {
            defaults?.set(data, forKey: Keys.savedSubscriptions)
        }
    }

    public func getSubscriptions() -> [VpnSubscription] {
        guard let data = defaults?.data(forKey: Keys.savedSubscriptions),
              let list = try? JSONDecoder().decode([VpnSubscription].self, from: data) else {
            return []
        }
        return list
    }
}
