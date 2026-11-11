import SwiftUI
import SplateCore

public struct SubscriptionsView: View {
    @ObservedObject var appState: AppState

    @State private var showingAddSheet = false
    @State private var newSubName = ""
    @State private var newSubUrl = ""

    public var body: some View {
        NavigationView {
            ZStack {
                SplateTheme.backgroundDark
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Presets Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ПРЕДУСТАНОВЛЕННЫЕ СПИСКИ (RU)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(SplateTheme.textTertiary)
                                .padding(.horizontal, 16)

                            VStack(spacing: 8) {
                                PresetCard(
                                    title: SplateConstants.presetWhiteCidrName,
                                    subtitle: "Прямой доступ к государственным и локальным ресурсам",
                                    icon: "shield.lefthalf.filled",
                                    isAdded: appState.subscriptions.contains { $0.url == SplateConstants.presetWhiteCidrUrl }
                                ) {
                                    appState.addSubscription(
                                        name: SplateConstants.presetWhiteCidrName,
                                        url: SplateConstants.presetWhiteCidrUrl
                                    )
                                }

                                PresetCard(
                                    title: SplateConstants.presetHarvesterName,
                                    subtitle: "Автоматически протестированные рабочие узлы VLESS",
                                    icon: "antenna.radiowaves.left.and.right",
                                    isAdded: appState.subscriptions.contains { $0.url == SplateConstants.presetHarvesterUrl }
                                ) {
                                    appState.addSubscription(
                                        name: SplateConstants.presetHarvesterName,
                                        url: SplateConstants.presetHarvesterUrl
                                    )
                                }

                                PresetCard(
                                    title: SplateConstants.presetUniversalName,
                                    subtitle: "Универсальный белый список для обхода ограничений",
                                    icon: "globe.europe.africa.fill",
                                    isAdded: appState.subscriptions.contains { $0.url == SplateConstants.presetUniversalUrl }
                                ) {
                                    appState.addSubscription(
                                        name: SplateConstants.presetUniversalName,
                                        url: SplateConstants.presetUniversalUrl
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.top, 10)

                        // User Subscriptions Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("АКТИВНЫЕ ПОДПИСКИ")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(SplateTheme.textTertiary)

                                Spacer()

                                Button {
                                    appState.refreshAllSubscriptions()
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.clockwise")
                                            .rotationEffect(.degrees(appState.isUpdatingSubscriptions ? 360 : 0))
                                            .animation(
                                                appState.isUpdatingSubscriptions ?
                                                    Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                                value: appState.isUpdatingSubscriptions
                                            )
                                        Text("Обновить все")
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(SplateTheme.accentCyan)
                                }
                            }
                            .padding(.horizontal, 16)

                            if appState.subscriptions.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 36))
                                        .foregroundColor(SplateTheme.textTertiary)
                                    Text("Нет добавленных подписок")
                                        .font(.system(size: 14))
                                        .foregroundColor(SplateTheme.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                                .glassCard(cornerRadius: 16)
                                .padding(.horizontal, 16)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(appState.subscriptions) { sub in
                                        SubscriptionCard(sub: sub) {
                                            appState.refreshSubscription(sub)
                                        } onDelete: {
                                            if let idx = appState.subscriptions.firstIndex(where: { $0.id == sub.id }) {
                                                appState.deleteSubscription(at: IndexSet(integer: idx))
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Подписки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(SplateTheme.accentCyan)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddSubscriptionSheet(appState: appState)
            }
        }
    }
}

public struct PresetCard: View {
    public let title: String
    public let subtitle: String
    public let icon: String
    public let isAdded: Bool
    public let onAdd: () -> Void

    public var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isAdded ? SplateTheme.accentEmerald : SplateTheme.primaryBlue)
                .frame(width: 36, height: 36)
                .background((isAdded ? SplateTheme.accentEmerald : SplateTheme.primaryBlue).opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SplateTheme.textPrimary)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(SplateTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if isAdded {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(SplateTheme.accentEmerald)
                    .padding(8)
                    .background(SplateTheme.accentEmerald.opacity(0.12))
                    .clipShape(Circle())
            } else {
                Button(action: onAdd) {
                    Text("Добавить")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SplateTheme.accentCyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(SplateTheme.accentCyan.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 14)
    }
}

public struct SubscriptionCard: View {
    public let sub: VpnSubscription
    public let onRefresh: () -> Void
    public let onDelete: () -> Void

    public var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(sub.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(SplateTheme.textPrimary)

                    Text("\(sub.nodeCount) узлов")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(SplateTheme.accentCyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(SplateTheme.accentCyan.opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(sub.url)
                    .font(.system(size: 11))
                    .foregroundColor(SplateTheme.textTertiary)
                    .lineLimit(1)

                Text("Обновлено: \(formattedDate(sub.lastUpdated))")
                    .font(.system(size: 10))
                    .foregroundColor(SplateTheme.textSecondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(SplateTheme.textSecondary)
                        .padding(8)
                        .background(SplateTheme.surfaceElevated)
                        .clipShape(Circle())
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(SplateTheme.accentCrimson)
                        .padding(8)
                        .background(SplateTheme.accentCrimson.opacity(0.12))
                        .clipShape(Circle())
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 16)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

public struct AddSubscriptionSheet: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var url: String = ""

    public var body: some View {
        NavigationView {
            ZStack {
                SplateTheme.backgroundDark
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Название подписки")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(SplateTheme.textSecondary)

                        TextField("Например: Мой сервер", text: $name)
                            .foregroundColor(SplateTheme.textPrimary)
                            .padding(12)
                            .glassCard(cornerRadius: 12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("URL подписки")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(SplateTheme.textSecondary)

                        TextField("https://...", text: $url)
                            .foregroundColor(SplateTheme.textPrimary)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(12)
                            .glassCard(cornerRadius: 12)
                    }

                    Spacer()

                    Button {
                        guard !url.isEmpty else { return }
                        let finalName = name.isEmpty ? "Подписка" : name
                        appState.addSubscription(name: finalName, url: url)
                        dismiss()
                    } label: {
                        Text("Добавить и обновить")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(SplateTheme.backgroundDeep)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(SplateTheme.accentCyan)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(20)
            }
            .navigationTitle("Новая подписка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(SplateTheme.textSecondary)
                }
            }
        }
    }
}
