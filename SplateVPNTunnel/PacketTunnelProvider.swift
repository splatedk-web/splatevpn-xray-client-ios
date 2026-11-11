import NetworkExtension
import Foundation
import SplateCore

open class PacketTunnelProvider: NEPacketTunnelProvider {

    private var isTunnelActive = false

    open override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        AppGroupStorage.shared.setVpnStatus(.connecting)

        guard let activeNode = AppGroupStorage.shared.getActiveServer() else {
            let error = NSError(domain: "SplateVPN", code: -1, userInfo: [NSLocalizedDescriptionKey: "Сервер не выбран"])
            AppGroupStorage.shared.setVpnStatus(.failed)
            completionHandler(error)
            return
        }

        // Configure Virtual Network Adapter
        let tunnelSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: SplateConstants.loopbackAddress)

        // IPv4 configuration
        let ipv4Settings = NEIPv4Settings(
            addresses: [SplateConstants.tunIpv4Address],
            subnetMasks: [SplateConstants.tunIpv4Netmask]
        )
        ipv4Settings.includedRoutes = [NEIPv4Route.default()]
        tunnelSettings.ipv4Settings = ipv4Settings

        // DNS configuration
        let dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        dnsSettings.matchDomains = [""] // Intercept all DNS queries
        tunnelSettings.dnsSettings = dnsSettings

        tunnelSettings.mtu = 1500

        setTunnelNetworkSettings(tunnelSettings) { [weak self] error in
            if let error = error {
                AppGroupStorage.shared.setVpnStatus(.failed)
                completionHandler(error)
                return
            }

            self?.startCoreEngine(with: activeNode)
            self?.isTunnelActive = true
            AppGroupStorage.shared.setVpnStatus(.connected)
            completionHandler(nil)
        }
    }

    open override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        stopCoreEngine()
        isTunnelActive = false
        AppGroupStorage.shared.setVpnStatus(.disconnected)
        completionHandler()
    }

    open override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        // Can be used for live stats query from UI
        let stats = AppGroupStorage.shared.getTrafficStats()
        if let responseData = try? JSONEncoder().encode(stats) {
            completionHandler?(responseData)
        } else {
            completionHandler?(nil)
        }
    }

    open override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    open override func wake() {
        // Handle wake event
    }

    // MARK: - Core Engine Bridge

    private func startCoreEngine(with node: ServerNode) {
        let mode = AppGroupStorage.shared.getRoutingMode()
        let configJson = XrayConfigGenerator.generate(node: node, routingMode: mode)

        // Bridge to hev-socks5-tunnel & Xray embedded core:
        // When XCFramework is linked:
        // 1. write config to local container
        // 2. start Xray with configJson
        // 3. start hev-socks5-tunnel with packetFlow file descriptor
        NSLog("[SplateTunnel] Started tunnel engine for node: \(node.name) (\(node.protocolType.rawValue))")
    }

    private func stopCoreEngine() {
        NSLog("[SplateTunnel] Stopped tunnel engine")
    }
}
