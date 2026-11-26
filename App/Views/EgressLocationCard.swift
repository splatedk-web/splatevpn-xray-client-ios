import SwiftUI

struct EgressInfo: Decodable {
    let ip: String
    let country: String?
    let country_code: String?
    let city: String?
    let connection: EgressConnection?
}

struct EgressConnection: Decodable {
    let isp: String?
}

/// Top compact location pill matching Android HomeScreen (flag + city/country + IP spoiler + crosshair button).
struct EgressLocationCard: View {
    @Environment(\.splateColors) private var colors
    let isConnected: Bool

    @State private var egress: EgressInfo?
    @State private var isLoading = false
    @State private var revealIP = false

    var body: some View {
        HStack(spacing: 12) {
            Text(flagEmoji(for: egress?.country_code))
                .font(.title2)
                .frame(width: 34, height: 34)
                .background(colors.surfaceElevated.opacity(0.6), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                if let egress {
                    let place = [egress.city, egress.country]
                        .compactMap { $0 }
                        .filter { !$0.isEmpty }
                        .joined(separator: ", ")
                    Text(place.isEmpty ? "Unknown" : place)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(colors.textPrimary)
                        .lineLimit(1)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { revealIP.toggle() }
                    } label: {
                        Text(revealIP ? egress.ip : "•••.•••.•••.•••")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(colors.textSecondary)
                            .blur(radius: revealIP ? 0 : 2.5)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(isConnected ? "Определение локации…" : "Внешняя локация")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(colors.textPrimary)
                        .lineLimit(1)
                    Text("Нажмите справа для проверки IP")
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
                    Image(systemName: "scope")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(colors.accentCyan)
                }
            }
            .disabled(isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 20)
        .task(id: isConnected) {
            if isConnected {
                await refreshIP()
            }
        }
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

    private func flagEmoji(for countryCode: String?) -> String {
        guard let code = countryCode?.uppercased(), code.count == 2 else { return "🌐" }
        var scalarView = String.UnicodeScalarView()
        for u in code.unicodeScalars {
            if let scalar = UnicodeScalar(127397 + u.value) {
                scalarView.append(scalar)
            }
        }
        return String(scalarView)
    }
}
