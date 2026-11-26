import SwiftUI

struct QuickServerPickerSheet: View {
    @EnvironmentObject private var vpn: VPNManager
    @Environment(\.splateColors) private var colors
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if vpn.state.servers.count > 1 {
                    Button {
                        Task {
                            await vpn.pingAllServers(autoSelectFastest: true)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Label(vpn.l10n.autoSelectFastest, systemImage: "bolt.horizontal.circle.fill")
                                .foregroundStyle(colors.accentCyan)
                            Spacer()
                            if vpn.isPinging {
                                ProgressView().controlSize(.small)
                            }
                        }
                    }
                }

                ForEach(vpn.state.servers) { server in
                    Button {
                        vpn.selectServer(server)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(server.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text(server.displaySubtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if let ping = server.pingMs {
                                Text("\(ping) ms")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(ping < 150 ? .green : (ping < 350 ? .orange : .red))
                            }
                            if vpn.state.selectedServer?.id == server.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(colors.accentCyan)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Выбор узла")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(vpn.l10n.cancel) { dismiss() }
                }
            }
        }
    }
}
