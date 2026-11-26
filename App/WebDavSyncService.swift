import Foundation

enum WebDavError: LocalizedError {
    case invalidURL
    case httpStatus(Int)
    case emptyPayload

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Некорректный WebDAV URL"
        case .httpStatus(let code): return "WebDAV сервер вернул HTTP \(code)"
        case .emptyPayload: return "Файл бэкапа на WebDAV пуст"
        }
    }
}

enum WebDavSyncService {
    static func upload(document: String, urlString: String, username: String, password: String) async throws {
        guard let url = resolveTargetURL(urlString) else { throw WebDavError.invalidURL }
        var req = URLRequest(url: url, timeoutInterval: 25)
        req.httpMethod = "PUT"
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        applyAuth(&req, username: username, password: password)
        req.httpBody = Data(document.utf8)

        let (_, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw WebDavError.httpStatus(http.statusCode)
        }
    }

    static func download(urlString: String, username: String, password: String) async throws -> String {
        guard let url = resolveTargetURL(urlString) else { throw WebDavError.invalidURL }
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 25)
        req.httpMethod = "GET"
        applyAuth(&req, username: username, password: password)

        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw WebDavError.httpStatus(http.statusCode)
        }
        guard let text = String(data: data, encoding: .utf8), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WebDavError.emptyPayload
        }
        return text
    }

    private static func resolveTargetURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var url = URL(string: trimmed), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
            return nil
        }
        if url.path.isEmpty || url.path.hasSuffix("/") {
            url.appendPathComponent("splatevpn-backup.json")
        }
        return url
    }

    private static func applyAuth(_ request: inout URLRequest, username: String, password: String) {
        guard !username.isEmpty || !password.isEmpty else { return }
        let token = Data("\(username):\(password)".utf8).base64EncodedString()
        request.setValue("Basic \(token)", forHTTPHeaderField: "Authorization")
    }
}
