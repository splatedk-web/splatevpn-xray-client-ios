import AppIntents
import NetworkExtension
import SwiftUI
import WidgetKit

struct SplateWidgetEntry: TimelineEntry {
    let date: Date
    let serverName: String
    let isConnected: Bool
}

struct SplateTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SplateWidgetEntry {
        SplateWidgetEntry(date: Date(), serverName: "SplateVPN", isConnected: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SplateWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SplateWidgetEntry>) -> Void) {
        let entry = currentEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> SplateWidgetEntry {
        let state = SharedStateStore.shared.load()
        let connected = UserDefaults(suiteName: AppGroup.identifier)?.bool(forKey: "vpn_is_connected") ?? false
        return SplateWidgetEntry(
            date: Date(),
            serverName: state.selectedServer?.name ?? "SplateVPN",
            isConnected: connected
        )
    }
}

struct SplateStatusWidgetView: View {
    let entry: SplateWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: entry.isConnected ? "shield.checkered" : "shield.slash")
                    .font(.title2)
                    .foregroundStyle(entry.isConnected ? .green : .secondary)
                Spacer()
                Circle()
                    .fill(entry.isConnected ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: 10, height: 10)
            }
            Spacer()
            Text(entry.serverName)
                .font(.headline)
                .lineLimit(1)
            Text(entry.isConnected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct SplateStatusWidget: Widget {
    let kind = "SplateStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SplateTimelineProvider()) { entry in
            SplateStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("SplateVPN")
        .description("Статус подключения и активный сервер SplateVPN.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@available(iOS 18.0, *)
struct ToggleVPNControlIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Toggle SplateVPN"

    @Parameter(title: "Connected")
    var value: Bool

    func perform() async throws -> some IntentResult {
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        if let manager = managers.first(where: {
            ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == AppGroup.tunnelBundleIdentifier
        }) {
            if value {
                try manager.connection.startVPNTunnel()
            } else {
                manager.connection.stopVPNTunnel()
            }
        }
        return .result()
    }
}

@available(iOS 18.0, *)
struct SplateControlWidget: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "SplateVPNControl") {
            ControlWidgetToggle(
                "SplateVPN",
                isOn: UserDefaults(suiteName: AppGroup.identifier)?.bool(forKey: "vpn_is_connected") ?? false,
                action: ToggleVPNControlIntent()
            ) { isOn in
                Label(isOn ? "VPN On" : "VPN Off", systemImage: isOn ? "shield.fill" : "shield.slash")
            }
        }
        .displayName("SplateVPN")
        .description("Быстрое включение и выключение SplateVPN из Пункта управления.")
    }
}

@main
struct SplateWidgetBundle: WidgetBundle {
    var body: some Widget {
        SplateStatusWidget()
        if #available(iOS 18.0, *) {
            SplateControlWidget()
        }
    }
}
