import SwiftUI
import UIKit

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case servers
    case rules
    case settings

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .home: return "shield.lefthalf.filled"
        case .servers: return "server.rack"
        case .rules: return "point.3.connected.trianglepath.dotted"
        case .settings: return "slider.horizontal.3"
        }
    }

    func title(l10n: L10n) -> String {
        switch self {
        case .home: return l10n.tabHome
        case .servers: return l10n.tabServers
        case .rules: return l10n.routingSection
        case .settings: return l10n.tabSettings
        }
    }

    static func visibleTabs(for mode: AppUiMode) -> [AppTab] {
        mode.isSimple ? [.home, .settings] : AppTab.allCases
    }
}

struct FloatingLiquidDock: View {
    @Environment(\.splateColors) private var colors
    @Environment(\.glassTransparency) private var transparency

    @Binding var selectedTab: AppTab
    let tabs: [AppTab]
    let l10n: L10n

    @Namespace private var pillNamespace
    @State private var dragHoverIndex: Int?

    var body: some View {
        let scrimScale = max(0.85, min(1.0, 1.0 - transparency))

        ZStack(alignment: .bottom) {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: colors.background.opacity((colors.isDark ? 0.45 : 0.35) * scrimScale), location: 0.30),
                    .init(color: colors.background.opacity(0.88 * scrimScale), location: 0.55),
                    .init(color: colors.background, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 112)
            .allowsHitTesting(false)

            GeometryReader { geo in
                let activeIdx = dragHoverIndex ?? (tabs.firstIndex(of: selectedTab) ?? 0)
                HStack(spacing: 0) {
                    ForEach(Array(tabs.enumerated()), id: \.element.id) { index, tab in
                        let isSelected = index == activeIdx
                        Button {
                            select(tab)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tab.systemImage)
                                    .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                                Text(tab.title(l10n: l10n))
                                    .font(.system(size: 10, weight: .semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundStyle(isSelected ? colors.accentCyan : colors.textSecondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(colors.accentCyan.opacity(colors.isDark ? 0.16 : 0.13))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .strokeBorder(colors.accentCyan.opacity(0.32), lineWidth: 1)
                                        )
                                        .matchedGeometryEffect(id: "dockPill", in: pillNamespace)
                                }
                            }
                        }
                        .buttonStyle(ElasticButtonStyle(targetScale: 0.95))
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            let count = max(1, tabs.count)
                            let idx = max(0, min(count - 1, Int((value.location.x / max(1, geo.size.width)) * CGFloat(count))))
                            if dragHoverIndex != idx {
                                dragHoverIndex = idx
                                UISelectionFeedbackGenerator().selectionChanged()
                            }
                        }
                        .onEnded { _ in
                            if let idx = dragHoverIndex, idx < tabs.count {
                                select(tabs[idx])
                            }
                            dragHoverIndex = nil
                        }
                )
            }
            .padding(4)
            .frame(maxWidth: 600)
            .frame(height: 64)
            .liquidGlass(cornerRadius: 24, innerSheen: true)
            .shadow(color: Color.black.opacity(colors.isDark ? 0.45 : 0.14), radius: 14, y: 6)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.80), value: selectedTab)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: dragHoverIndex)
    }

    private func select(_ tab: AppTab) {
        guard selectedTab != tab else { return }
        selectedTab = tab
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
