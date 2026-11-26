import Foundation
import SplateCore

public enum CoreBridgeError: LocalizedError {
    case invalidPayload(String)
    case coreFailure(String)

    public var errorDescription: String? {
        switch self {
        case .invalidPayload(let detail): return detail
        case .coreFailure(let detail): return detail
        }
    }
}

public enum CoreBridge {
    private static let decoder = JSONDecoder()

    public static var coreVersion: String {
        MobileCoreVersion()
    }

    public static func applyExtensionMemoryLimit(megabytes: Int64 = 32) {
        MobileApplyMemoryLimit(megabytes)
    }

    public static func parseSubscriptionLink(_ raw: String) throws -> ResolvedSubscriptionLink {
        var err: NSError?
        let json = MobileParseSubscriptionLink(raw, &err)
        if let err {
            throw CoreBridgeError.coreFailure(err.localizedDescription)
        }
        guard let data = json.data(using: .utf8) else {
            throw CoreBridgeError.invalidPayload("Invalid UTF-8 response from Core")
        }
        return try decoder.decode(ResolvedSubscriptionLink.self, from: data)
    }

    public static func parseServerLink(_ raw: String) throws -> ServerProfile {
        var err: NSError?
        let json = MobileParseServerLink(raw, &err)
        if let err {
            throw CoreBridgeError.coreFailure(err.localizedDescription)
        }
        guard let data = json.data(using: .utf8) else {
            throw CoreBridgeError.invalidPayload("Invalid UTF-8 response from Core")
        }
        return try decoder.decode(ServerProfile.self, from: data)
    }

    public static func parseServerSubscription(_ raw: String) throws -> [ServerProfile] {
        var err: NSError?
        let json = MobileParseServerSubscription(raw, &err)
        if let err {
            throw CoreBridgeError.coreFailure(err.localizedDescription)
        }
        guard let data = json.data(using: .utf8) else {
            throw CoreBridgeError.invalidPayload("Invalid UTF-8 response from Core")
        }
        return try decoder.decode([ServerProfile].self, from: data)
    }

    public static func measureTCPDelay(address: String, port: Int, timeoutMs: Int = 3000) -> Int? {
        var ms: Int64 = -1
        var err: NSError?
        let ok = MobileMeasureTCPDelay(address, port, timeoutMs, &ms, &err)
        guard ok, err == nil, ms > 0 else { return nil }
        return Int(ms)
    }

    public static func measureURLDelay(
        link: String,
        fullConfigJson: String,
        targetURL: String = "http://www.gstatic.com/generate_204",
        timeoutMs: Int = 5000
    ) -> Int? {
        var ms: Int64 = -1
        var err: NSError?
        let ok = MobileMeasureURLDelay(link, fullConfigJson, targetURL, timeoutMs, &ms, &err)
        guard ok, err == nil, ms > 0 else { return nil }
        return Int(ms)
    }

    public static func encryptBackup(plaintextJSON: String, password: String) throws -> String {
        var err: NSError?
        let encrypted = MobileEncryptBackup(plaintextJSON, password, &err)
        if let err {
            throw CoreBridgeError.coreFailure(err.localizedDescription)
        }
        return encrypted
    }

    public static func decryptBackup(document: String, password: String) throws -> String {
        var err: NSError?
        let plain = MobileDecryptBackup(document, password, &err)
        if let err {
            throw CoreBridgeError.coreFailure(err.localizedDescription)
        }
        return plain
    }
}
