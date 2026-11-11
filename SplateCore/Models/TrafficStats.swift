import Foundation

public struct TrafficStats: Codable, Hashable {
    public var uploadBytes: Int64
    public var downloadBytes: Int64
    public var uploadSpeed: Int64
    public var downloadSpeed: Int64

    public init(
        uploadBytes: Int64 = 0,
        downloadBytes: Int64 = 0,
        uploadSpeed: Int64 = 0,
        downloadSpeed: Int64 = 0
    ) {
        self.uploadBytes = uploadBytes
        self.downloadBytes = downloadBytes
        self.uploadSpeed = uploadSpeed
        self.downloadSpeed = downloadSpeed
    }

    public static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }

    public static func formatSpeed(_ bytesPerSecond: Int64) -> String {
        return "\(formatBytes(bytesPerSecond))/s"
    }
}
