import Foundation

public final class XrayConfigGenerator {
    public static func generate(
        node: ServerNode,
        routingMode: RoutingMode = .bypassRu,
        socksPort: UInt16 = SplateConstants.xraySocksPort
    ) -> String {
        var config: [String: Any] = [:]

        // Log
        config["log"] = ["loglevel": "warning"]

        // Inbounds: local SOCKS5 proxy on 127.0.0.1:socksPort
        config["inbounds"] = [
            [
                "tag": "socks-in",
                "listen": SplateConstants.loopbackAddress,
                "port": Int(socksPort),
                "protocol": "socks",
                "settings": [
                    "auth": "noauth",
                    "udp": true
                ],
                "sniffing": [
                    "enabled": true,
                    "destOverride": ["http", "tls", "quic"],
                    "routeOnly": false
                ]
            ]
        ]

        // Outbound: Proxy Node
        var proxyOutbound: [String: Any] = [
            "tag": "proxy",
            "protocol": node.protocolType.rawValue
        ]

        // Outbound settings depending on protocol
        switch node.protocolType {
        case .vless:
            var user: [String: Any] = [
                "id": node.uuid,
                "encryption": node.encryption.isEmpty ? "none" : node.encryption
            ]
            if !node.flow.isEmpty {
                user["flow"] = node.flow
            }
            proxyOutbound["settings"] = [
                "vnext": [
                    [
                        "address": node.address,
                        "port": node.port,
                        "users": [user]
                    ]
                ]
            ]

        case .vmess:
            proxyOutbound["settings"] = [
                "vnext": [
                    [
                        "address": node.address,
                        "port": node.port,
                        "users": [
                            [
                                "id": node.uuid,
                                "alterId": 0,
                                "security": "auto"
                            ]
                        ]
                    ]
                ]
            ]

        case .trojan:
            proxyOutbound["settings"] = [
                "servers": [
                    [
                        "address": node.address,
                        "port": node.port,
                        "password": node.uuid
                    ]
                ]
            ]

        case .shadowsocks:
            proxyOutbound["settings"] = [
                "servers": [
                    [
                        "address": node.address,
                        "port": node.port,
                        "method": node.encryption,
                        "password": node.uuid
                    ]
                ]
            ]
        }

        // Stream Settings (Transport + TLS/Reality)
        var streamSettings: [String: Any] = [
            "network": node.network.isEmpty ? "tcp" : node.network
        ]

        if node.security == "reality" {
            streamSettings["security"] = "reality"
            var reality: [String: Any] = [
                "show": false,
                "fingerprint": node.fingerprint.isEmpty ? "chrome" : node.fingerprint,
                "serverName": node.sni.isEmpty ? node.address : node.sni,
                "publicKey": node.publicKey,
                "shortId": node.shortId,
                "spiderX": node.spiderX
            ]
            streamSettings["realitySettings"] = reality
        } else if node.security == "tls" {
            streamSettings["security"] = "tls"
            var tls: [String: Any] = [
                "serverName": node.sni.isEmpty ? node.address : node.sni,
                "allowInsecure": false,
                "fingerprint": node.fingerprint.isEmpty ? "chrome" : node.fingerprint
            ]
            streamSettings["tlsSettings"] = tls
        }

        // Network Specifics (WS / gRPC / HTTPUpgrade)
        if node.network == "ws" {
            var ws: [String: Any] = [
                "path": node.path.isEmpty ? "/" : node.path
            ]
            if !node.host.isEmpty {
                ws["headers"] = ["Host": node.host]
            }
            streamSettings["wsSettings"] = ws
        } else if node.network == "grpc" {
            streamSettings["grpcSettings"] = [
                "serviceName": node.path
            ]
        }

        proxyOutbound["streamSettings"] = streamSettings

        // Outbounds list
        config["outbounds"] = [
            proxyOutbound,
            [
                "tag": "direct",
                "protocol": "freedom",
                "settings": [:]
            ],
            [
                "tag": "block",
                "protocol": "blackhole",
                "settings": [:]
            ]
        ]

        // DNS
        config["dns"] = [
            "servers": [
                "https://1.1.1.1/dns-query",
                "8.8.8.8",
                "localhost"
            ]
        ]

        // Routing Rules
        var rules: [[String: Any]] = []
        if routingMode == .bypassRu {
            rules.append([
                "type": "field",
                "outboundTag": "direct",
                "domain": ["geosite:category-ru", "domain:ru", "domain:su", "domain:xn--p1ai"]
            ])
            rules.append([
                "type": "field",
                "outboundTag": "direct",
                "ip": ["geoip:ru", "geoip:private"]
            ])
        }

        rules.append([
            "type": "field",
            "outboundTag": "proxy",
            "network": "tcp,udp"
        ])

        config["routing"] = [
            "domainStrategy": "IPIfNonMatch",
            "rules": rules
        ]

        if let data = try? JSONSerialization.data(withJSONObject: config, options: [.prettyPrinted]),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }

        return "{}"
    }
}
