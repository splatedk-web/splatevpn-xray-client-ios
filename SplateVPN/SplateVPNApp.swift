import SwiftUI
import SplateCore

@main
struct SplateVPNApp: App {
    @StateObject private var appState = AppState()
    @State private var selectedTab = 0

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                SplateTheme.backgroundDark
                    .ignoresSafeArea()

                TabView(selection: $selectedTab) {
                    HomeScreen(appState: appState, selectedTab: $selectedTab)
                        .tabItem {
                            Label("Главная", systemImage: "bolt.shield.fill")
                        }
                        .tag(0)

                    ServersView(appState: appState)
                        .tabItem {
                            Label("Узлы", systemImage: "server.rack")
                        }
                        .tag(1)

                    SubscriptionsView(appState: appState)
                        .tabItem {
                            Label("Подписки", systemImage: "list.bullet.rectangle")
                        }
                        .tag(2)

                    SettingsView(appState: appState)
                        .tabItem {
                            Label("Настройки", systemImage: "gearshape.fill")
                        }
                        .tag(3)
                }
                .tint(SplateTheme.accentCyan)
            }
            .preferredColorScheme(.dark)
            .alert(isPresented: Binding(
                get: { appState.errorMessage != nil },
                set: { if !$0 { appState.errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Уведомление"),
                    message: Text(appState.errorMessage ?? ""),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func configureAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(SplateTheme.surfaceDark.opacity(0.95))

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(SplateTheme.textPrimary)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(SplateTheme.textPrimary)]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
}
