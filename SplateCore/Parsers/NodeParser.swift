import Foundation

public final class NodeParser {
    public static func parse(link: String) -> ServerNode? {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.starts(with: "vless://") {
            return parseVless(trimmed)
        } else if trimmed.starts(with: "vmess://") {
            return parseVmess(trimmed)
        } else if trimmed.starts(with: "trojan://") {
            return parseTrojan(trimmed)
        } else if trimmed.starts(with: "ss://") {
            return parseShadowsocks(trimmed)
        }
        return nil
    }

    private static func parseVless(_ link: String) -> ServerNode? {
        guard let url = URL(string: link),
              let host = url.host,
              let port = url.port else { return nil }

        let uuid = url.user ?? ""
        let fragment = url.fragment?.removingPercentEncoding ?? "VLESS Server"

        var queryParams: [String: String] = [:]
        if let components = URLComponents(string: link), let queryItems = components.queryItems {
            for item in queryItems {
                queryParams[item.name] = item.value ?? ""
            }
        }

        return ServerNode(
            name: fragment,
            protocolType: .vless,
            address: host,
            port: port,
            uuid: uuid,
            flow: queryParams["flow"] ?? "",
            encryption: queryParams["encryption"] ?? "none",
            network: queryParams["type"] ?? "tcp",
            security: queryParams["security"] ?? "none",
            sni: queryParams["sni"] ?? "",
            fingerprint: queryParams["fp"] ?? "chrome",
            publicKey: queryParams["pbk"] ?? "",
            shortId: queryParams["sid"] ?? "",
            spiderX: queryParams["spx"] ?? "",
            path: queryParams["path"]?.removingPercentEncoding ?? "",
            host: queryParams["host"] ?? "",
            rawLink: link
        )
    }

    private static func parseVmess(_ link: String) -> ServerNode? {
        let base64Part = String(link.dropFirst("vmess://".count))
        guard let decodedData = decodeBase64(base64Part),
              let json = try? JSONSerialization.jsonObject(with: decodedData) as? [String: Any] else {
            return nil
        }

        let name = json["ps"] as? String ?? "VMess Server"
        let address = json["add"] as? String ?? ""
        let portInt: Int
        if let p = json["port"] as? Int {
            portInt = p
        } else if let pStr = json["port"] as? String, let p = Int(pStr) {
            portInt = p
        } else {
            portInt = 443
        }
        let uuid = json["id"] as? String ?? ""
        let network = json["net"] as? String ?? "tcp"
        let security = json["tls"] as? String ?? "none"
        let sni = json["sni"] as? String ?? ""
        let path = json["path"] as? String ?? ""
        let host = json["host"] as? String ?? ""

        return ServerNode(
            name: name,
            protocolType: .vmess,
            address: address,
            port: portInt,
            uuid: uuid,
            network: network,
            security: security,
            sni: sni,
            path: path,
            host: host,
            rawLink: link
        )
    }

    private static func parseTrojan(_ link: String) -> ServerNode? {
        guard let url = URL(string: link),
              let host = url.host,
              let port = url.port else { return nil }

        let password = url.user ?? ""
        let fragment = url.fragment?.removingPercentEncoding ?? "Trojan Server"

        var queryParams: [String: String] = [:]
        if let components = URLComponents(string: link), let queryItems = components.queryItems {
            for item in queryItems {
                queryParams[item.name] = item.value ?? ""
            }
        }

        return ServerNode(
            name: fragment,
            protocolType: .trojan,
            address: host,
            port: port,
            uuid: password,
            network: queryParams["type"] ?? "tcp",
            security: queryParams["security"] ?? "tls",
            sni: queryParams["sni"] ?? "",
            rawLink: link
        )
    }

    private static func parseShadowsocks(_ link: String) -> ServerNode? {
        let content = String(link.dropFirst("ss://".count))
        let parts = content.split(separator: "#", maxSplits: 1).map(String.init)
        let serverPart = parts[0]
        let name = parts.count > 1 ? parts[1].removingPercentEncoding ?? "Shadowsocks Server" : "Shadowsocks Server"

        if serverPart.contains("@") {
            let userHost = serverPart.split(separator: "@", maxSplits: 1).map(String.init)
            let hostPort = userHost[1].split(separator: ":").map(String.init)
            guard hostPort.count == 2, let port = Int(hostPort[1]) else { return nil }

            var method = ""
            var password = ""
            if let decoded = decodeBase64(userHost[0]), let userStr = String(data: decoded, encoding: .utf8) {
                let mp = userStr.split(separator: ":", maxSplits: 1).map(String.init)
                if mp.count == 2 {
                    method = mp[0]
                    password = mp[1]
                }
            }

            return ServerNode(
                name: name,
                protocolType: .shadowsocks,
                address: hostPort[0],
                port: port,
                uuid: password,
                encryption: method,
                rawLink: link
            )
        }
        return nil
    }

    private static func decodeBase64(_ base64: String) -> Data? {
        var normalized = base64
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let remainder = normalized.count % 4
        if remainder > 0 {
            normalized.append(String(repeating: "=", count: 4 - remainder))
        }
        return Data(base64Encoded: normalized)
    }
}
