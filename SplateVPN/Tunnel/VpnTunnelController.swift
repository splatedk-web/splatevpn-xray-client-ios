import Foundation
import NetworkExtension
import Combine
import SplateCore

public final class VpnTunnelController: ObservableObject {
    public static let shared = VpnTunnelController()

    @Published public private(set) var status: VpnStatus = .disconnected
    private var tunnelManager: NETunnelProviderManager?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        self.status = AppGroupStorage.shared.getVpnStatus()
        setupTunnelManager()
        observeStatusChanges()
    }

    public func setupTunnelManager(completion: ((Bool) -> Void)? = nil) {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("[VpnTunnelController] Failed to load preferences: \(error.localizedDescription)")
                completion?(false)
                return
            }

            if let existingManager = managers?.first(where: {
                ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == SplateConstants.tunnelBundleId
            }) {
                self.tunnelManager = existingManager
            } else {
                let newManager = NETunnelProviderManager()
                let p = NETunnelProviderProtocol()
                p.providerBundleIdentifier = SplateConstants.tunnelBundleId
                p.serverAddress = "SplateVPN"
                newManager.protocolConfiguration = p
                newManager.localizedDescription = "SplateVPN Tunnel"
                newManager.isEnabled = true
                self.tunnelManager = newManager
            }

            self.updateStatusFromManager()
            completion?(true)
        }
    }

    private func observeStatusChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusDidChange(_:)),
            name: .NEVPNStatusDidChange,
            object: nil
        )
    }

    @objc private func vpnStatusDidChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.updateStatusFromManager()
        }
    }

    private func updateStatusFromManager() {
        guard let connection = tunnelManager?.connection else {
            self.status = .disconnected
            return
        }

        switch connection.status {
        case .connected:
            self.status = .connected
        case .connecting:
            self.status = .connecting
        case .disconnecting:
            self.status = .disconnecting
        case .disconnected:
            self.status = .disconnected
        case .invalid, .reasserting:
            self.status = .connecting
        @unknown default:
            self.status = .disconnected
        }
        AppGroupStorage.shared.setVpnStatus(self.status)
    }

    public func startVpn(server: ServerNode, mode: RoutingMode, completion: @escaping (Result<Void, Error>) -> Void) {
        AppGroupStorage.shared.saveActiveServer(server)
        AppGroupStorage.shared.setRoutingMode(mode)

        guard let manager = tunnelManager else {
            setupTunnelManager { [weak self] success in
                if success {
                    self?.startVpn(server: server, mode: mode, completion: completion)
                } else {
                    let err = NSError(domain: "SplateVPN", code: -1, userInfo: [NSLocalizedDescriptionKey: "VPN менеджер недоступен"])
                    completion(.failure(err))
                }
            }
            return
        }

        manager.isEnabled = true
        manager.saveToPreferences { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }

            manager.loadFromPreferences { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                do {
                    try manager.connection.startVPNTunnel()
                    self?.status = .connecting
                    AppGroupStorage.shared.setVpnStatus(.connecting)
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    public func stopVpn() {
        tunnelManager?.connection.stopVPNTunnel()
        self.status = .disconnecting
        AppGroupStorage.shared.setVpnStatus(.disconnecting)
    }
}
