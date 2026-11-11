import Foundation

public struct Subscription: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var url: String
    public var lastUpdated: Date
    public var nodeCount: Int
    public var autoUpdate: Bool
    public var uploadBytes: Int64
    public var downloadBytes: Int64
    public var totalBytes: Int64
    public var expireTimestamp: Int64
    public var enabled: Bool
    public var lastError: String

    public init(
        id: String = UUID().uuidString,
        name: String,
        url: String,
        lastUpdated: Date = Date(),
        nodeCount: Int = 0,
        autoUpdate: Bool = true,
        uploadBytes: Int64 = 0,
        downloadBytes: Int64 = 0,
        totalBytes: Int64 = 0,
        expireTimestamp: Int64 = 0,
        enabled: Bool = true,
        lastError: String = ""
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.lastUpdated = lastUpdated
        self.nodeCount = nodeCount
        self.autoUpdate = autoUpdate
        self.uploadBytes = uploadBytes
        self.downloadBytes = downloadBytes
        self.totalBytes = totalBytes
        self.expireTimestamp = expireTimestamp
        self.enabled = enabled
        self.lastError = lastError
    }
}
