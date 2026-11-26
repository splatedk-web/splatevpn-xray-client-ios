import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var vpn: VPNManager

    private var l10n: L10n { vpn.l10n }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 72))
                    .foregroundStyle(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))

                VStack(spacing: 8) {
                    Text(l10n.onboardingTitle)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text(l10n.onboardingSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                Form {
                    Section(l10n.language) {
                        Picker(l10n.language, selection: Binding(
                            get: { vpn.state.languageCode },
                            set: { vpn.setLanguage($0) }
                        )) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section(l10n.routingSection) {
                        Picker(l10n.routingSection, selection: Binding(
                            get: { vpn.state.settings.routingMode },
                            set: { mode in vpn.updateSettings { $0.routingMode = mode } }
                        )) {
                            ForEach(RoutingMode.allCases) { mode in
                                Text(l10n.routingTitle(mode)).tag(mode)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }
                .frame(maxHeight: 340)
                .scrollContentBackground(.hidden)

                Button {
                    vpn.completeOnboarding()
                } label: {
                    Text(l10n.startUsing)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)

                Spacer()
            }
            .environment(\.layoutDirection, l10n.lang.layoutDirection)
        }
    }
}
