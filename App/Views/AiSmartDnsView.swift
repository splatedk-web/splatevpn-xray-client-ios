import SwiftUI

private struct SmartDnsOption: Identifiable {
    let key: String
    let label: String
    let host: String
    var id: String { key }
}

private let smartDnsOptions: [SmartDnsOption] = [
    .init(key: "dns_ai", label: "DNS-AI", host: "dns.dns-ai.ru"),
    .init(key: "geohide", label: "GeoHide RU", host: "geohide.ru"),
    .init(key: "geohide_eu", label: "GeoHide EU", host: "eu.geohide.ru"),
    .init(key: "malw", label: "MALW", host: "dns.malw.link"),
    .init(key: "malw_gateway", label: "MALW · CF", host: "5u35p8m9i7.cloudflare-gateway.com"),
    .init(key: "zapret_dns", label: "Zapret DNS", host: "dns.zapret.moe"),
    .init(key: "dagami", label: "Dagami", host: "dns.dagami.ru"),
    .init(key: "wlrus", label: "WLRus", host: "dns.wlrus.cfd"),
    .init(key: "geodema", label: "Geodema · Beta", host: "dns.geodema.love")
]

struct AiSmartDnsView: View {
    @EnvironmentObject private var vpn: VPNManager
    @Environment(\.splateColors) private var colors
    @State private var probeResult: String?
    @State private var isProbing = false

    var body: some View {
        Form {
            Section {
                Toggle("Включить AI SmartDNS", isOn: Binding(
                    get: { vpn.state.settings.enableAiSmartDns },
                    set: { v in vpn.updateSettings { $0.enableAiSmartDns = v } }
                ))
            } footer: {
                Text("Направляет домены ChatGPT, Gemini, Claude, Copilot, Perplexity, Grok и Cursor через выбранный SmartDNS DoH напрямую, не затрагивая остальные сервисы.")
            }

            Section("Провайдер SmartDNS") {
                ForEach(smartDnsOptions) { opt in
                    Button {
                        vpn.updateSettings { $0.aiDnsProvider = opt.key }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(opt.label).foregroundStyle(.primary)
                                Text(opt.host).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if vpn.state.settings.aiDnsProvider == opt.key {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(colors.accentCyan)
                            }
                        }
                    }
                }
            }

            Section("Проверка провайдера") {
                Button {
                    Task { await probeSelectedProvider() }
                } label: {
                    HStack {
                        Text("Проверить доступность DoH")
                        Spacer()
                        if isProbing { ProgressView().controlSize(.small) }
                    }
                }
                .disabled(isProbing)

                if let probeResult {
                    Text(probeResult)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Нейросети (SmartDNS)")
    }

    private func probeSelectedProvider() async {
        isProbing = true
        defer { isProbing = false }
        let selected = smartDnsOptions.first(where: { $0.key == vpn.state.settings.aiDnsProvider }) ?? smartDnsOptions[0]
        let start = Date()
        guard let url = URL(string: "https://\(selected.host)/dns-query") else { return }
        var req = URLRequest(url: url, timeoutInterval: 6)
        req.httpMethod = "HEAD"
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            probeResult = "\(selected.label): отвечает (HTTP \(code), \(ms) ms)"
        } catch {
            probeResult = "\(selected.label): недоступен (\(error.localizedDescription))"
        }
    }
}
