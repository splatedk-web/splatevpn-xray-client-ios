import SwiftUI

private struct ServiceCheckItem: Identifiable {
    let name: String
    let url: String
    var id: String { name }
}

private let serviceChecks: [ServiceCheckItem] = [
    .init(name: "YouTube", url: "https://www.youtube.com/generate_204"),
    .init(name: "Telegram", url: "https://core.telegram.org/"),
    .init(name: "ChatGPT", url: "https://chatgpt.com/"),
    .init(name: "Gemini", url: "https://gemini.google.com/"),
    .init(name: "Cloudflare DNS", url: "https://1.1.1.1/dns-query")
]

struct DiagnosticsView: View {
    @EnvironmentObject private var vpn: VPNManager
    @State private var speedMbps: Double?
    @State private var isTestingSpeed = false
    @State private var checkResults: [String: String] = [:]
    @State private var isCheckingServices = false

    var body: some View {
        Form {
            Section("Тест скорости (Cloudflare 10 МБ)") {
                Button {
                    Task { await runSpeedtest() }
                } label: {
                    HStack {
                        Label("Запустить Speedtest", systemImage: "speedometer")
                        Spacer()
                        if isTestingSpeed {
                            ProgressView().controlSize(.small)
                        } else if let speedMbps {
                            Text(String(format: "%.1f Мбит/с", speedMbps))
                                .font(.subheadline.monospacedDigit().weight(.semibold))
                                .foregroundStyle(.green)
                        }
                    }
                }
                .disabled(isTestingSpeed)
            }

            Section("Проверка доступности сервисов") {
                Button {
                    Task { await runServiceChecks() }
                } label: {
                    HStack {
                        Label("Проверить сервисы", systemImage: "checkmark.circle.badge.questionmark")
                        Spacer()
                        if isCheckingServices { ProgressView().controlSize(.small) }
                    }
                }
                .disabled(isCheckingServices)

                ForEach(serviceChecks) { item in
                    LabeledContent(item.name, value: checkResults[item.name] ?? "—")
                }
            }

            Section("Система и журнал") {
                NavigationLink(vpn.l10n.logsTitle) {
                    LogsView()
                }
                LabeledContent("GeoIP / GeoSite", value: AssetInstaller.hasGeoAssetsInstalled ? "OK" : "—")
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Диагностика")
    }

    private func runSpeedtest() async {
        isTestingSpeed = true
        defer { isTestingSpeed = false }
        guard let url = URL(string: "https://speed.cloudflare.com/__down?bytes=10000000") else { return }
        let start = Date()
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let elapsed = max(0.05, Date().timeIntervalSince(start))
            speedMbps = (Double(data.count) * 8.0) / (elapsed * 1_000_000.0)
        } catch {
            speedMbps = 0
        }
    }

    private func runServiceChecks() async {
        isCheckingServices = true
        defer { isCheckingServices = false }
        for item in serviceChecks {
            guard let url = URL(string: item.url) else { continue }
            var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 6)
            req.httpMethod = "HEAD"
            let start = Date()
            do {
                let (_, resp) = try await URLSession.shared.data(for: req)
                let ms = Int(Date().timeIntervalSince(start) * 1000)
                let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
                checkResults[item.name] = "OK (\(code), \(ms) ms)"
            } catch {
                checkResults[item.name] = "Ошибка"
            }
        }
    }
}
