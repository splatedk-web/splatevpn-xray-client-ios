import Foundation

public enum ProtocolType: String, Codable, CaseIterable {
    case vless
    case vmess
    case trojan
    case shadowsocks

    public var displayName: String {
        switch self {
        case .vless: return "VLESS"
        case .vmess: return "VMess"
        case .trojan: return "Trojan"
        case .shadowsocks: return "Shadowsocks"
        }
    }
}

public struct ServerNode: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var protocolType: ProtocolType
    public var address: String
    public var port: Int
    public var uuid: String
    public var flow: String
    public var encryption: String
    public var network: String // tcp, ws, grpc, xhttp
    public var security: String // reality, tls, none
    public var sni: String
    public var fingerprint: String
    public var publicKey: String
    public var shortId: String
    public var spiderX: String
    public var path: String
    public var host: String
    public var ping: Int64
    public var rawLink: String
    public var isSelected: Bool
    public var subId: String
    public var subName: String
    public var lastVerifiedAt: Int64

    public init(
        id: String = UUID().uuidString,
        name: String,
        protocolType: ProtocolType,
        address: String,
        port: Int,
        uuid: String = "",
        flow: String = "",
        encryption: String = "none",
        network: String = "tcp",
        security: String = "none",
        sni: String = "",
        fingerprint: String = "chrome",
        publicKey: String = "",
        shortId: String = "",
        spiderX: String = "",
        path: String = "",
        host: String = "",
        ping: Int64 = 0,
        rawLink: String = "",
        isSelected: Bool = false,
        subId: String = "",
        subName: String = "",
        lastVerifiedAt: Int64 = 0
    ) {
        self.id = id
        self.name = name
        self.protocolType = protocolType
        self.address = address
        self.port = port
        self.uuid = uuid
        self.flow = flow
        self.encryption = encryption
        self.network = network
        self.security = security
        self.sni = sni
        self.fingerprint = fingerprint
        self.publicKey = publicKey
        self.shortId = shortId
        self.spiderX = spiderX
        self.path = path
        self.host = host
        self.ping = ping
        self.rawLink = rawLink
        self.isSelected = isSelected
        self.subId = subId
        self.subName = subName
        self.lastVerifiedAt = lastVerifiedAt
    }
}
