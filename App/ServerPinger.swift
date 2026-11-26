import Foundation

enum ServerPinger {
    static func pingAll(
        servers: [ServerProfile],
        mode: PingMode,
        maxConcurrency: Int = 6
    ) async -> [UUID: Int] {
        guard !servers.isEmpty else { return [:] }
        var results: [UUID: Int] = [:]

        await withTaskGroup(of: (UUID, Int?).self) { group in
            var index = 0
            let initial = min(maxConcurrency, servers.count)
            for _ in 0..<initial {
                let server = servers[index]
                index += 1
                group.addTask {
                    await measureOne(server: server, mode: mode)
                }
            }

            while let (id, latency) = await group.next() {
                if let latency {
                    results[id] = latency
                }
                if index < servers.count {
                    let nextServer = servers[index]
                    index += 1
                    group.addTask {
                        await measureOne(server: nextServer, mode: mode)
                    }
                }
            }
        }
        return results
    }

    private static func measureOne(server: ServerProfile, mode: PingMode) async -> (UUID, Int?) {
        await Task.detached(priority: .utility) {
            let ms: Int?
            switch mode {
            case .tcp:
                ms = CoreBridge.measureTCPDelay(address: server.address, port: server.port, timeoutMs: 3000)
            case .realDelay:
                ms = CoreBridge.measureURLDelay(
                    link: server.rawLink,
                    fullConfigJson: server.fullConfigJson,
                    timeoutMs: 5000
                )
            }
            return (server.id, ms)
        }.value
    }
}
