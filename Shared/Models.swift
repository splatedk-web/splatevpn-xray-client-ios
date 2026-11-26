import Foundation

public struct ServerProfile: Codable, Identifiable, Equatable, Hashable {
    public var uuid: UUID = UUID()
    public var protocolName: String
    public var name: String
    public var description: String
    public var address: String
    public var port: Int
    public var username: String
    public var password: String
    public var userID: String
    public var flow: String
    public var encryption: String
    public var network: String
    public var security: String
    public var sni: String
    public var fingerprint: String
    public var publicKey: String
    public var shortId: String
    public var spiderX: String
    public var path: String
    public var host: String
    public var mode: String
    public var padding: String
    public var rawLink: String
    public var fullConfigJson: String
    public var subscriptionID: UUID?
    public var pingMs: Int?

    public var id: UUID { uuid }

    enum CodingKeys: String, CodingKey {
        case uuid
        case protocolName = "protocol"
        case name
        case description
        case address
        case port
        case username
        case password
        case userID = "id"
        case flow
        case encryption
        case network
        case security
        case sni
        case fingerprint
        case publicKey
        case shortId
        case spiderX
        case path
        case host
        case mode
        case padding
        case rawLink
        case fullConfigJson
        case subscriptionID
        case pingMs
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        uuid = try c.decodeIfPresent(UUID.self, forKey: .uuid) ?? UUID()
        protocolName = try c.decodeIfPresent(String.self, forKey: .protocolName) ?? ""
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        address = try c.decodeIfPresent(String.self, forKey: .address) ?? ""
        port = try c.decodeIfPresent(Int.self, forKey: .port) ?? 443
        username = try c.decodeIfPresent(String.self, forKey: .username) ?? ""
        password = try c.decodeIfPresent(String.self, forKey: .password) ?? ""
        userID = try c.decodeIfPresent(String.self, forKey: .userID) ?? ""
        flow = try c.decodeIfPresent(String.self, forKey: .flow) ?? ""
        encryption = try c.decodeIfPresent(String.self, forKey: .encryption) ?? ""
        network = try c.decodeIfPresent(String.self, forKey: .network) ?? "tcp"
        security = try c.decodeIfPresent(String.self, forKey: .security) ?? "none"
        sni = try c.decodeIfPresent(String.self, forKey: .sni) ?? ""
        fingerprint = try c.decodeIfPresent(String.self, forKey: .fingerprint) ?? "chrome"
        publicKey = try c.decodeIfPresent(String.self, forKey: .publicKey) ?? ""
        shortId = try c.decodeIfPresent(String.self, forKey: .shortId) ?? ""
        spiderX = try c.decodeIfPresent(String.self, forKey: .spiderX) ?? ""
        path = try c.decodeIfPresent(String.self, forKey: .path) ?? ""
        host = try c.decodeIfPresent(String.self, forKey: .host) ?? ""
        mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? "auto"
        padding = try c.decodeIfPresent(String.self, forKey: .padding) ?? ""
        rawLink = try c.decodeIfPresent(String.self, forKey: .rawLink) ?? ""
        fullConfigJson = try c.decodeIfPresent(String.self, forKey: .fullConfigJson) ?? ""
        subscriptionID = try c.decodeIfPresent(UUID.self, forKey: .subscriptionID)
        pingMs = try c.decodeIfPresent(Int.self, forKey: .pingMs)
    }

    public var displaySubtitle: String {
        let proto = protocolName.uppercased()
        let net = network.uppercased()
        let sec = security == "none" ? "" : " • \(security.uppercased())"
        return "\(proto) • \(net)\(sec) • \(address):\(port)"
    }
}

public struct SubscriptionRecord: Codable, Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var url: String
    public var updatedAt: Date
    public var uploadBytes: Int64?
    public var downloadBytes: Int64?
    public var totalBytes: Int64?
    public var expireTimestamp: Int64?

    public init(
        id: UUID = UUID(),
        name: String,
        url: String,
        updatedAt: Date = Date(),
        uploadBytes: Int64? = nil,
        downloadBytes: Int64? = nil,
        totalBytes: Int64? = nil,
        expireTimestamp: Int64? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.updatedAt = updatedAt
        self.uploadBytes = uploadBytes
        self.downloadBytes = downloadBytes
        self.totalBytes = totalBytes
        self.expireTimestamp = expireTimestamp
    }
}

public struct ResolvedSubscriptionLink: Codable, Equatable {
    public let url: String
    public let name: String
}

public enum RoutingMode: String, Codable, CaseIterable, Identifiable {
    case smartRU = "smart_ru"
    case global = "global"
    case whitelist = "whitelist"

    public var id: String { rawValue }
}

public enum BalancerGoal: String, Codable, CaseIterable, Identifiable {
    case general = "general"
    case youtube = "youtube"
    case gaming = "gaming"
    case ai = "ai"

    public var id: String { rawValue }

    public var titleRu: String {
        switch self {
        case .general: return "Обычный"
        case .youtube: return "YouTube"
        case .gaming: return "Игры"
        case .ai: return "Нейросети"
        }
    }
}

public enum BalancerMetric: String, Codable, CaseIterable, Identifiable {
    case latency = "latency"
    case stability = "stability"
    case speed = "speed"

    public var id: String { rawValue }

    public var titleRu: String {
        switch self {
        case .latency: return "Задержка"
        case .stability: return "Стабильность"
        case .speed: return "Скорость"
        }
    }
}

public enum PingMode: String, Codable, CaseIterable, Identifiable {
    case realDelay = "real_delay"
    case tcp = "tcp"

    public var id: String { rawValue }
}

public struct TunnelSettings: Codable, Equatable {
    public var mtu: Int = 1400
    public var routingMode: RoutingMode = .smartRU
    public var autoBalancerEnabled: Bool = true
    public var balancerGoal: BalancerGoal = .general
    public var balancerMetric: BalancerMetric = .latency
    public var dnsServer: String = "1.1.1.1"
    public var sniffing: Bool = true
    public var blockQuic: Bool = true
    public var enableAdBlock: Bool = false
    public var enableTlsFragment: Bool = false
    public var enableIpv6: Bool = false
    public var enableAiSmartDns: Bool = false
    public var aiDnsProvider: String = "dns_ai"
    public var shareLanProxy: Bool = false
    public var lanProxyPort: Int = 10809
    public var lanProxyUser: String = ""
    public var lanProxyPass: String = ""
    public var webdavUrl: String = ""
    public var webdavUser: String = ""
    public var pingMode: PingMode = .realDelay
    public var customDirectDomains: [String] = []
    public var customProxyDomains: [String] = []
    public var customBlockDomains: [String] = []

    public init() {}

    public func toCoreOptionsJSON(assetsDir: String) -> String {
        let payload: [String: Any] = [
            "mtu": mtu,
            "routingMode": routingMode.rawValue,
            "dnsServer": dnsServer,
            "sniffing": sniffing,
            "blockQuic": blockQuic,
            "enableAdBlock": enableAdBlock,
            "enableTlsFragment": enableTlsFragment,
            "enableIpv6": enableIpv6,
            "enableAiSmartDns": enableAiSmartDns,
            "aiDnsProvider": aiDnsProvider,
            "shareLanProxy": shareLanProxy,
            "lanProxyPort": lanProxyPort,
            "lanProxyUser": lanProxyUser,
            "lanProxyPass": lanProxyPass,
            "assetsDir": assetsDir,
            "customDirectDomains": customDirectDomains,
            "customProxyDomains": customProxyDomains,
            "customBlockDomains": customBlockDomains
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }
}

public enum AppUiMode: String, Codable, CaseIterable, Identifiable {
    case simple = "simple"
    case advanced = "advanced"

    public var id: String { rawValue }
    public var isSimple: Bool { self == .simple }
}

public struct AppStateSnapshot: Codable, Equatable {
    public var servers: [ServerProfile] = []
    public var subscriptions: [SubscriptionRecord] = []
    public var selectedServerID: UUID?
    public var settings: TunnelSettings = TunnelSettings()
    public var hasCompletedOnboarding: Bool = false
    public var languageCode: String = "ru"
    public var themeKey: String = "dark"
    public var glassTransparency: Double = 0.25
    public var glassBlurEnabled: Bool = true
    public var uiMode: AppUiMode = .advanced

    public init() {}

    public var selectedServer: ServerProfile? {
        guard let selectedServerID else { return servers.first }
        return servers.first(where: { $0.id == selectedServerID }) ?? servers.first
    }
}

public struct TrafficStats: Codable, Equatable {
    public let uplink: Int64
    public let downlink: Int64

    public static let zero = TrafficStats(uplink: 0, downlink: 0)
}

public enum TunnelIPCCommand: String, Codable {
    case trafficStats
}
