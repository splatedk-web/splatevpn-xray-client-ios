import SwiftUI

struct EgressInfo: Decodable {
    let ip: String
    let country: String?
    let city: String?
    let connection: EgressConnection?
}

struct EgressConnection: Decodable {
    let isp: String?
}

struct EgressLocationCard: View {
    @Environment(\.splateColors) private var colors
    let isConnected: Bool

    @State private var egress: EgressInfo?
    @State private var isLoading = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isConnected ? "globe.europe.africa.fill" : "globe")
                .font(.title3)
                .foregroundStyle(isConnected ? colors.accentConnected : colors.accentCyan)
                .frame(width: 36, height: 36)
                .background((isConnected ? colors.accentConnected : colors.accentCyan).opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                if let egress {
                    Text(egress.ip)
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(colors.textPrimary)
                    let loc = [egress.country, egress.city, egress.connection?.isp]
                        .compactMap { $0 }
                        .filter { !$0.isEmpty }
                        .joined(separator: " • ")
                    Text(loc.isEmpty ? "—" : loc)
                        .font(.caption)
                        .foregroundStyle(colors.textSecondary)
                        .lineLimit(1)
                } else {
                    Text("Внешний IP и локация")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(colors.textPrimary)
                    Text("Нажмите справа, чтобы проверить выходной адрес")
                        .font(.caption)
                        .foregroundStyle(colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                Task { await refreshIP() }
            } label: {
                if isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(colors.accentCyan)
                }
            }
            .disabled(isLoading)
        }
        .padding(14)
        .liquidGlass(cornerRadius: 18)
    }

    private func refreshIP() async {
        isLoading = true
        defer { isLoading = false }
        guard let url = URL(string: "https://ipwho.is/") else { return }
        var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
        req.setValue("SplateVPN-iOS/1.0", forHTTPHeaderField: "User-Agent")
        if let (data, _) = try? await URLSession.shared.data(for: req),
           let decoded = try? JSONDecoder().decode(EgressInfo.self, from: data) {
            egress = decoded
        }
    }
}
