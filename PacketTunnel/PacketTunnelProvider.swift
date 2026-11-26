import Darwin
import Foundation
import NetworkExtension
import SplateCore
import os.log

final class PacketTunnelProvider: NEPacketTunnelProvider {
    private let logger = Logger(subsystem: "com.danieldk.splatevpn.PacketTunnel", category: "Tunnel")
    private var engine: MobileTunnelEngine?

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        CoreBridge.applyExtensionMemoryLimit(megabytes: 32)

        let state = SharedStateStore.shared.load()
        guard let server = state.selectedServer else {
            completionHandler(NSError(
                domain: "com.danieldk.splatevpn",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Не выбран сервер для подключения"]
            ))
            return
        }

        let settings = state.settings
        let tunnelSettings = buildNetworkSettings(settings: settings, serverAddress: server.address)

        setTunnelNetworkSettings(tunnelSettings) { [weak self] error in
            guard let self else { return }
            if let error {
                AppLogger.shared.log("setTunnelNetworkSettings error: \(error.localizedDescription)", source: "Tunnel", level: "ERROR")
                self.logger.error("Failed to apply tunnel network settings: \(error.localizedDescription, privacy: .public)")
                completionHandler(error)
                return
            }

            guard let (tunFd, ifName) = self.resolveTunnelFileDescriptor() else {
                AppLogger.shared.log("Could not resolve utun file descriptor", source: "Tunnel", level: "ERROR")
                completionHandler(NSError(
                    domain: "com.danieldk.splatevpn",
                    code: 1002,
                    userInfo: [NSLocalizedDescriptionKey: "Не удалось получить utun file descriptor"]
                ))
                return
            }

            guard let newEngine = MobileNewTunnelEngine() else {
                completionHandler(NSError(
                    domain: "com.danieldk.splatevpn",
                    code: 1003,
                    userInfo: [NSLocalizedDescriptionKey: "Не удалось инициализировать Xray engine"]
                ))
                return
            }

            do {
                let optionsJSON = settings.toCoreOptionsJSON(assetsDir: AppGroup.assetsDirectoryURL.path)
                try newEngine.start(
                    withOptionsJSON: server.rawLink,
                    fullConfigJSON: server.fullConfigJson,
                    fd: Int(tunFd),
                    optionsJSON: optionsJSON
                )
                self.engine = newEngine
                AppLogger.shared.log("Tunnel started: \(server.name) (\(server.protocolName)) on \(ifName) (fd=\(tunFd))", source: "Tunnel")
                self.logger.info("SplateVPN tunnel started for \(server.name, privacy: .public) on \(ifName, privacy: .public)")
                completionHandler(nil)
            } catch {
                AppLogger.shared.log("Tunnel start failed: \(error.localizedDescription)", source: "Tunnel", level: "ERROR")
                self.logger.error("Failed to start Xray core: \(error.localizedDescription, privacy: .public)")
                completionHandler(error)
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        AppLogger.shared.log("Stopping tunnel (reason: \(reason.rawValue))", source: "Tunnel")
        logger.info("Stopping SplateVPN tunnel (reason: \(reason.rawValue))")
        if let engine {
            try? engine.stop()
            self.engine = nil
        }
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        guard let completionHandler else { return }
        guard let command = try? JSONDecoder().decode(TunnelIPCCommand.self, from: messageData) else {
            completionHandler(nil)
            return
        }
        switch command {
        case .trafficStats:
            let json = engine?.trafficStatsJSON() ?? "{\"uplink\":0,\"downlink\":0}"
            completionHandler(json.data(using: .utf8))
        }
    }

    private func buildNetworkSettings(settings: TunnelSettings, serverAddress: String) -> NEPacketTunnelNetworkSettings {
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "198.18.0.1")
        networkSettings.mtu = NSNumber(value: max(1280, min(settings.mtu, 9000)))

        // IPv4 full-tunnel route
        let ipv4 = NEIPv4Settings(addresses: ["198.18.0.2"], subnetMasks: ["255.255.255.0"])
        ipv4.includedRoutes = [NEIPv4Route.default()]
        var excludedV4: [NEIPv4Route] = []
        if isIPv4Address(serverAddress) {
            excludedV4.append(NEIPv4Route(destinationAddress: serverAddress, subnetMask: "255.255.255.255"))
        }
        if settings.routingMode != .global {
            excludedV4.append(contentsOf: [
                NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
                NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
                NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
                NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0")
            ])
        }
        ipv4.excludedRoutes = excludedV4
        networkSettings.ipv4Settings = ipv4

        // Capture IPv6 as well so IPv6 traffic never leaks past the VPN tunnel.
        let ipv6 = NEIPv6Settings(addresses: ["fd00:198:18::2"], networkPrefixLengths: [64])
        ipv6.includedRoutes = [NEIPv6Route.default()]
        networkSettings.ipv6Settings = ipv6

        // Route all DNS through the tunnel where Xray's dns-out handles it.
        let dns = NEDNSSettings(servers: ["198.18.0.1", "1.1.1.1"])
        dns.matchDomains = [""]
        networkSettings.dnsSettings = dns

        return networkSettings
    }

    private func isIPv4Address(_ value: String) -> Bool {
        var addr = in_addr()
        return value.withCString { inet_pton(AF_INET, $0, &addr) == 1 }
    }

    /// Resolves the genuine Darwin utun file descriptor by verifying UTUN_OPT_IFNAME ("utun*").
    private func resolveTunnelFileDescriptor() -> (Int32, String)? {
        if let fd = packetFlow.value(forKeyPath: "socket.fileDescriptor") as? Int32, fd >= 3 {
            if let name = utunInterfaceName(for: fd) {
                return (fd, name)
            }
            return (fd, "utun")
        }
        // Scan open descriptors and verify via getsockopt(SYSPROTO_CONTROL=2, UTUN_OPT_IFNAME=2)
        // so we never accidentally pick a non-utun AF_SYSTEM socket.
        for fd: Int32 in 3..<1024 {
            if let name = utunInterfaceName(for: fd), name.hasPrefix("utun") {
                return (fd, name)
            }
        }
        return nil
    }

    private func utunInterfaceName(for fd: Int32) -> String? {
        var nameBuf = [CChar](repeating: 0, count: Int(IFNAMSIZ) + 1)
        var len = socklen_t(nameBuf.count)
        let sysprotoControl: Int32 = 2
        let utunOptIfname: Int32 = 2
        let rc = getsockopt(fd, sysprotoControl, utunOptIfname, &nameBuf, &len)
        guard rc == 0 else { return nil }
        let name = String(cString: nameBuf)
        return name.isEmpty ? nil : name
    }
}
