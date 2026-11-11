import Foundation

public final class SubscriptionParser {
    public static func parseSubscriptionContent(_ rawContent: String, subscriptionId: String, subscriptionName: String) -> [ServerNode] {
        var content = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)

        // If it's valid Base64, decode it
        if let data = Data(base64Encoded: content, options: [.ignoreUnknownCharacters]),
           let decoded = String(data: data, encoding: .utf8),
           decoded.contains("://") {
            content = decoded
        }

        let lines = content.components(separatedBy: .newlines)
        var nodes: [ServerNode] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !trimmed.starts(with: "#") else { continue }

            if var node = NodeParser.parse(link: trimmed) {
                node.subId = subscriptionId
                node.subName = subscriptionName
                nodes.append(node)
            }
        }

        return nodes
    }
}
