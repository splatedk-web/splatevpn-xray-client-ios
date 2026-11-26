import Foundation
import UIKit

enum SubscriptionServiceError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid subscription URL"
        case .httpError(let code): return "Subscription server returned HTTP \(code)"
        case .emptyResponse: return "Empty subscription response"
        }
    }
}

struct SubscriptionFetchResult {
    let profiles: [ServerProfile]
    let title: String?
    let uploadBytes: Int64?
    let downloadBytes: Int64?
    let totalBytes: Int64?
    let expireTimestamp: Int64?
}

enum SubscriptionService {
    private static let hwidKey = "com.danieldk.splatevpn.hwid"

    static func fetch(from urlString: String) async throws -> SubscriptionFetchResult {
        guard let url = URL(string: urlString) else {
            throw SubscriptionServiceError.invalidURL
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("SplateVPN-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue(deviceHWID(), forHTTPHeaderField: "x-hwid")
        request.setValue("iOS", forHTTPHeaderField: "x-device-os")
        request.setValue(UIDevice.current.systemVersion, forHTTPHeaderField: "x-ver-os")
        request.setValue(UIDevice.current.model, forHTTPHeaderField: "x-device-model")

        let (data, response) = try await URLSession.shared.data(for: request)
        var title: String?
        var upload: Int64?
        var download: Int64?
        var total: Int64?
        var expire: Int64?

        if let http = response as? HTTPURLResponse {
            if !(200...299).contains(http.statusCode) {
                throw SubscriptionServiceError.httpError(http.statusCode)
            }
            if let rawTitle = http.value(forHTTPHeaderField: "profile-title") {
                title = decodeProfileTitle(rawTitle)
            }
            if let userInfo = http.value(forHTTPHeaderField: "subscription-userinfo") {
                let parsed = parseUserInfo(userInfo)
                upload = parsed["upload"]
                download = parsed["download"]
                total = parsed["total"]
                expire = parsed["expire"]
            }
        }

        guard let body = String(data: data, encoding: .utf8),
              !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SubscriptionServiceError.emptyResponse
        }
        let profiles = try CoreBridge.parseServerSubscription(body)
        return SubscriptionFetchResult(
            profiles: profiles,
            title: title,
            uploadBytes: upload,
            downloadBytes: download,
            totalBytes: total,
            expireTimestamp: expire
        )
    }

    private static func deviceHWID() -> String {
        if let existing = UserDefaults.standard.string(forKey: hwidKey), !existing.isEmpty {
            return existing
        }
        let created = (UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString)
            .replacingOccurrences(of: "-", with: "")
            .lowercased()
        UserDefaults.standard.set(created, forKey: hwidKey)
        return created
    }

    private static func decodeProfileTitle(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("base64:") {
            let b64 = String(trimmed.dropFirst("base64:".count))
            if let data = Data(base64Encoded: b64), let decoded = String(data: data, encoding: .utf8) {
                return decoded.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func parseUserInfo(_ header: String) -> [String: Int64] {
        var result: [String: Int64] = [:]
        for part in header.split(separator: ";") {
            let pair = part.split(separator: "=", maxSplits: 1)
            guard pair.count == 2 else { continue }
            let key = pair[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let valText = pair[1].trimmingCharacters(in: .whitespacesAndNewlines)
            if let num = Int64(valText) {
                result[key] = num
            }
        }
        return result
    }
}
