import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var vpn: VPNManager
    @Environment(\.colorScheme) private var systemScheme
    @Environment(\.splateColors) private var colors

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Режим интерфейса")
                        .font(.headline)
                        .foregroundStyle(colors.textPrimary)

                    Picker("Режим интерфейса", selection: Binding(
                        get: { vpn.state.uiMode },
                        set: { vpn.setUiMode($0) }
                    )) {
                        Text("Простой").tag(AppUiMode.simple)
                        Text("Расширенный").tag(AppUiMode.advanced)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(16)
                .liquidGlass(cornerRadius: 20)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Прозрачность стекла")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(colors.textPrimary)
                        Spacer()
                        Text("\(Int(vpn.state.glassTransparency * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(colors.textSecondary)
                    }
                    Slider(
                        value: Binding(
                            get: { vpn.state.glassTransparency },
                            set: { vpn.setGlassTransparency($0) }
                        ),
                        in: 0...1
                    )
                    .tint(colors.accentCyan)

                    Toggle("Размытие стекла (Blur)", isOn: Binding(
                        get: { vpn.state.glassBlurEnabled },
                        set: { vpn.setGlassBlurEnabled($0) }
                    ))
                    .foregroundStyle(colors.textPrimary)
                    .tint(colors.accentCyan)
                }
                .padding(16)
                .liquidGlass(cornerRadius: 20)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(SplateThemeKey.allCases) { key in
                        let palette = AppThemeColors.resolve(themeKey: key.rawValue, isSystemDark: systemScheme == .dark)
                        let selected = SplateThemeKey.canonical(vpn.state.themeKey) == key

                        Button {
                            vpn.setThemeKey(key.rawValue)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Circle().fill(palette.accentCyan).frame(width: 14, height: 14)
                                    Circle().fill(palette.accentSecondary).frame(width: 14, height: 14)
                                    Circle().fill(palette.ambientB).frame(width: 14, height: 14)
                                    Spacer()
                                    if selected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(palette.accentCyan)
                                    }
                                }
                                Text(key.title(lang: vpn.l10n.lang))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(palette.textPrimary)
                                    .lineLimit(1)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(
                                    colors: [palette.background, palette.surface],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(selected ? palette.accentCyan : palette.borderSubtle, lineWidth: selected ? 2 : 1)
                            )
                        }
                        .buttonStyle(ElasticButtonStyle())
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 100)
        }
        .background(Color.clear)
        .navigationTitle("Темы и стекло")
    }
}
