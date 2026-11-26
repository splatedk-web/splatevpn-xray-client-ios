import Foundation

public enum AppGroup {
    public static let identifier = "group.com.danieldk.splatevpn"
    public static let tunnelBundleIdentifier = "com.danieldk.splatevpn.PacketTunnel"

    public static var containerURL: URL {
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) {
            return url
        }
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    public static var assetsDirectoryURL: URL {
        let dir = containerURL.appendingPathComponent("Assets", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public static var stateFileURL: URL {
        containerURL.appendingPathComponent("splate_state.json")
    }

    public static var logsFileURL: URL {
        containerURL.appendingPathComponent("splate_runtime.log")
    }
}

public final class SharedStateStore {
    public static let shared = SharedStateStore()
    private let queue = DispatchQueue(label: "com.danieldk.splatevpn.sharedstore", attributes: .concurrent)
    private let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        return enc
    }()
    private let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }()

    private init() {}

    public func load() -> AppStateSnapshot {
        queue.sync {
            guard let data = try? Data(contentsOf: AppGroup.stateFileURL),
                  let snapshot = try? decoder.decode(AppStateSnapshot.self, from: data) else {
                return AppStateSnapshot()
            }
            return snapshot
        }
    }

    public func save(_ snapshot: AppStateSnapshot) throws {
        var writeError: Error?
        queue.sync(flags: .barrier) {
            do {
                let data = try encoder.encode(snapshot)
                try data.write(to: AppGroup.stateFileURL, options: [.atomic])
            } catch {
                writeError = error
            }
        }
        if let writeError {
            throw writeError
        }
    }
}
