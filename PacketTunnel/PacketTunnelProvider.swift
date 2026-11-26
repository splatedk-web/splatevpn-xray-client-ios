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
        let tunnelSettings = buildNetworkSettings(settings: settings)

        setTunnelNetworkSettings(tunnelSettings) { [weak self] error in
            guard let self else { return }
            if let error {
                self.logger.error("Failed to apply tunnel network settings: \(error.localizedDescription, privacy: .public)")
                completionHandler(error)
                return
            }

            guard let tunFd = self.resolveTunnelFileDescriptor() else {
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
                AppLogger.shared.log("Tunnel started for \(server.name) (\(server.protocolName))", source: "Tunnel")
                self.logger.info("SplateVPN tunnel started for \(server.name, privacy: .public)")
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

    private func buildNetworkSettings(settings: TunnelSettings) -> NEPacketTunnelNetworkSettings {
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "198.18.0.1")
        networkSettings.mtu = NSNumber(value: max(1280, min(settings.mtu, 9000)))

        let ipv4 = NEIPv4Settings(addresses: ["198.18.0.2"], subnetMasks: ["255.255.255.0"])
        ipv4.includedRoutes = [NEIPv4Route.default()]
        if settings.routingMode != .global {
            ipv4.excludedRoutes = [
                NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
                NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
                NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
                NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0")
            ]
        }
        networkSettings.ipv4Settings = ipv4

        let dnsHost = extractDNSHost(settings.dnsServer)
        let dns = NEDNSSettings(servers: [dnsHost])
        dns.matchDomains = [""]
        networkSettings.dnsSettings = dns

        return networkSettings
    }

    private func extractDNSHost(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("https://"), let host = URL(string: trimmed)?.host, !host.isEmpty {
            return host
        }
        return trimmed.isEmpty ? "1.1.1.1" : trimmed
    }

    /// Resolves the Darwin utun file descriptor from NEPacketTunnelFlow or open socket scan.
    private func resolveTunnelFileDescriptor() -> Int32? {
        if let fd = packetFlow.value(forKeyPath: "socket.fileDescriptor") as? Int32, fd >= 3 {
            return fd
        }
        var ctlInfo = ctl_info()
        withUnsafeMutablePointer(to: &ctlInfo.ctl_name) {
            $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: ctlInfo.ctl_name)) { ptr in
                _ = strcpy(ptr, "com.apple.net.utun_control")
            }
        }
        for fd: Int32 in 3..<1024 {
            var addr = sockaddr_ctl()
            var len = socklen_t(MemoryLayout<sockaddr_ctl>.size)
            let ok = withUnsafeMutablePointer(to: &addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                    getpeername(fd, sa, &len) == 0
                }
            }
            if ok && addr.sc_family == AF_SYSTEM {
                return fd
            }
        }
        return nil
    }
}
