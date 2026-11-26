import SwiftUI

struct LogsView: View {
    @EnvironmentObject private var vpn: VPNManager
    @State private var logText = ""

    var body: some View {
        ScrollView {
            Text(logText.isEmpty ? "—" : logText)
                .font(.system(.caption, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding()
        }
        .navigationTitle(vpn.l10n.logsTitle)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    logText = AppLogger.shared.readAll()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }

                Button {
                    UIPasteboard.general.string = logText
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .disabled(logText.isEmpty)

                Button(role: .destructive) {
                    AppLogger.shared.clear()
                    logText = ""
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .onAppear {
            logText = AppLogger.shared.readAll()
        }
    }
}
