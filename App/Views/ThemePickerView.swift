import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var vpn: VPNManager
    @Environment(\.colorScheme) private var systemScheme
    @Environment(\.splateColors) private var colors
    @State private var showAllThemes = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var displayedThemes: [SplateThemeKey] {
        showAllThemes ? SplateThemeKey.allCases : Array(SplateThemeKey.allCases.prefix(4))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Theme Card matching Android 09_settings_appearance_themes.png
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "paintpalette.fill")
                            .font(.title3)
                            .foregroundStyle(colors.accentCyan)
                            .frame(width: 40, height: 40)
                            .background(colors.accentCyan.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Тема оформления")
                                .font(.headline)
                                .foregroundStyle(colors.textPrimary)
                            Text("Цветовая палитра и визуальный стиль")
                                .font(.caption)
                                .foregroundStyle(colors.textSecondary)
                        }
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(displayedThemes) { key in
                            let palette = AppThemeColors.resolve(themeKey: key.rawValue, isSystemDark: systemScheme == .dark)
                            let selected = SplateThemeKey.canonical(vpn.state.themeKey) == key

                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    vpn.setThemeKey(key.rawValue)
                                }
                            } label: {
                                VStack(spacing: 0) {
                                    // Mini UI mockup preview matching Android screenshot
                                    ZStack {
                                        LinearGradient(
                                            colors: [palette.background, palette.backgroundDeep],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(spacing: 6) {
                                                Circle().fill(palette.accentCyan).frame(width: 7, height: 7)
                                                RoundedRectangle(cornerRadius: 3).fill(palette.textPrimary.opacity(0.7)).frame(width: 48, height: 5)
                                                Spacer()
                                            }
                                            RoundedRectangle(cornerRadius: 3).fill(palette.textSecondary.opacity(0.45)).frame(width: 72, height: 4)
                                            HStack {
                                                HStack(spacing: 4) {
                                                    Circle().fill(palette.accentViolet).frame(width: 5, height: 5)
                                                    Circle().fill(palette.accentSecondary).frame(width: 5, height: 5)
                                                    Circle().fill(palette.accentEmerald).frame(width: 5, height: 5)
                                                }
                                                Spacer()
                                                Capsule().fill(palette.accentCyan).frame(width: 26, height: 9)
                                            }
                                        }
                                        .padding(10)
                                        .background(palette.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(palette.borderSubtle, lineWidth: 1)
                                        )
                                        .padding(10)
                                    }
                                    .frame(height: 92)

                                    HStack {
                                        Text(key.title(lang: vpn.l10n.lang))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(colors.textPrimary)
                                            .lineLimit(1)
                                        Spacer()
                                        if selected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.subheadline)
                                                .foregroundStyle(colors.accentCyan)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(colors.surface.opacity(0.9))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(selected ? colors.accentCyan : colors.borderSubtle, lineWidth: selected ? 2 : 1)
                                )
                            }
                            .buttonStyle(ElasticButtonStyle())
                        }
                    }

                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            showAllThemes.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(showAllThemes ? "Свернуть темы" : "Показать все темы (\(SplateThemeKey.allCases.count))")
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: showAllThemes ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .liquidGlass(cornerRadius: 14)
                    }
                    .buttonStyle(ElasticButtonStyle())
                }
                .padding(16)
                .liquidGlass(cornerRadius: 22)

                // Glass transparency & Blur
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

                // UI Mode
                VStack(alignment: .leading, spacing: 12) {
                    Text("Режим интерфейса")
                        .font(.subheadline.weight(.semibold))
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
            }
            .padding(16)
            .padding(.bottom, 100)
        }
        .background(Color.clear)
        .navigationTitle("Оформление и язык")
    }
}
