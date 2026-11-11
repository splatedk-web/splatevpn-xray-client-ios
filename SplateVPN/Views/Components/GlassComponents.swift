import SwiftUI
import SplateCore

public struct LatencyBadge: View {
    public let latency: Int64

    public var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(colorForLatency)
                .frame(width: 7, height: 7)

            Text(latency > 0 ? "\(latency) ms" : "—")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(colorForLatency)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(colorForLatency.opacity(0.12))
        .clipShape(Capsule())
    }

    private var colorForLatency: Color {
        if latency <= 0 {
            return SplateTheme.textTertiary
        } else if latency < 120 {
            return SplateTheme.accentEmerald
        } else if latency < 300 {
            return SplateTheme.accentAmber
        } else {
            return SplateTheme.accentCrimson
        }
    }
}

public struct HeroConnectButton: View {
    public let status: VpnStatus
    public let action: () -> Void

    @State private var isPulsing = false

    public var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glowing pulse ring
                if status == .connected || status == .connecting {
                    Circle()
                        .stroke(ringColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 190, height: 190)
                        .scaleEffect(isPulsing ? 1.15 : 0.95)
                        .opacity(isPulsing ? 0.0 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: false),
                            value: isPulsing
                        )
                }

                // Intermediate glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ringColor.opacity(0.25),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 90
                        )
                    )
                    .frame(width: 170, height: 170)

                // Main button background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                SplateTheme.surfaceElevated,
                                SplateTheme.surfaceDark
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        ringColor,
                                        ringColor.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    )
                    .shadow(color: ringColor.opacity(0.3), radius: 15, x: 0, y: 5)

                // Power Icon
                Image(systemName: "power")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(ringColor)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            isPulsing = true
        }
    }

    private var ringColor: Color {
        switch status {
        case .connected:
            return SplateTheme.accentCyan
        case .connecting, .disconnecting:
            return SplateTheme.accentAmber
        case .failed:
            return SplateTheme.accentCrimson
        case .disconnected:
            return SplateTheme.borderMedium
        }
    }
}

public struct ScaleButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

public struct TrafficWidgetView: View {
    public let stats: TrafficStats

    public var body: some View {
        HStack(spacing: 16) {
            // Download Card
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(SplateTheme.accentCyan)

                VStack(alignment: .leading, spacing: 2) {
                    Text("ВХОДЯЩИЙ")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(SplateTheme.textTertiary)

                    Text(TrafficStats.formatSpeed(stats.downloadSpeed))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(SplateTheme.textPrimary)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 16)

            // Upload Card
            HStack(spacing: 12) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(SplateTheme.accentViolet)

                VStack(alignment: .leading, spacing: 2) {
                    Text("ИСХОДЯЩИЙ")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(SplateTheme.textTertiary)

                    Text(TrafficStats.formatSpeed(stats.uploadSpeed))
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundColor(SplateTheme.textPrimary)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 16)
        }
    }
}
