import SwiftUI

struct RoutingRulesView: View {
    @EnvironmentObject private var vpn: VPNManager
    @State private var directText = ""
    @State private var proxyText = ""
    @State private var blockText = ""

    var body: some View {
        Form {
            Section("Direct (по одному домену на строку)") {
                TextEditor(text: $directText)
                    .frame(minHeight: 90)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Proxy (через VPN)") {
                TextEditor(text: $proxyText)
                    .frame(minHeight: 90)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("Block (блокировать)") {
                TextEditor(text: $blockText)
                    .frame(minHeight: 90)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .navigationTitle(vpn.l10n.customRules)
        .onAppear {
            directText = vpn.state.settings.customDirectDomains.joined(separator: "\n")
            proxyText = vpn.state.settings.customProxyDomains.joined(separator: "\n")
            blockText = vpn.state.settings.customBlockDomains.joined(separator: "\n")
        }
        .onDisappear {
            save()
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("OK") { save() }
            }
        }
    }

    private func save() {
        vpn.updateSettings { s in
            s.customDirectDomains = splitLines(directText)
            s.customProxyDomains = splitLines(proxyText)
            s.customBlockDomains = splitLines(blockText)
        }
    }

    private func splitLines(_ raw: String) -> [String] {
        raw.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
