import Foundation

public final class AppLogger {
    public static let shared = AppLogger()
    private let queue = DispatchQueue(label: "com.danieldk.splatevpn.logger")
    private let maxLogBytes = 256 * 1024
    private let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private init() {}

    public func log(_ message: String, source: String = "App", level: String = "INFO") {
        let line = "[\(formatter.string(from: Date()))] [\(source)] [\(level)] \(message)\n"
        queue.async {
            let url = AppGroup.logsFileURL
            if let data = line.data(using: .utf8) {
                if FileManager.default.fileExists(atPath: url.path),
                   let handle = try? FileHandle(forWritingTo: url) {
                    defer { try? handle.close() }
                    _ = try? handle.seekToEnd()
                    try? handle.write(contentsOf: data)
                } else {
                    try? data.write(to: url, options: [.atomic])
                }
                self.trimIfNeeded(url: url)
            }
        }
    }

    public func readAll() -> String {
        queue.sync {
            (try? String(contentsOf: AppGroup.logsFileURL, encoding: .utf8)) ?? ""
        }
    }

    public func clear() {
        queue.sync {
            try? FileManager.default.removeItem(at: AppGroup.logsFileURL)
        }
    }

    private func trimIfNeeded(url: URL) {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int,
              size > maxLogBytes,
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return
        }
        let suffix = String(content.suffix(maxLogBytes / 2))
        if let firstNewline = suffix.firstIndex(of: "\n") {
            let trimmed = String(suffix[suffix.index(after: firstNewline)...])
            try? trimmed.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
