import SwiftUI

enum SettingsGroup: String, CaseIterable, Identifiable {
    case essentials
    case networking
    case toolsData
    case system

    var id: String { rawValue }

    func title(russian: Bool) -> String {
        switch self {
        case .essentials: return russian ? "Основные" : "Essentials"
        case .networking: return russian ? "Сеть и маршруты" : "Network & routing"
        case .toolsData: return russian ? "Инструменты и данные" : "Tools & data"
        case .system: return russian ? "Система" : "System"
        }
    }
}

enum SettingsCategory: String, CaseIterable, Identifiable {
    case connection
    case appearance
    case protection
    case network
    case routing
    case ai
    case tor
    case sharing
    case backup
    case sync
    case diagnostics
    case advanced
    case about

    var id: String { rawValue }

    var group: SettingsGroup {
        switch self {
        case .connection, .appearance, .protection: return .essentials
        case .network, .routing, .ai, .tor: return .networking
        case .sharing, .backup, .sync, .diagnostics: return .toolsData
        case .advanced, .about: return .system
        }
    }

    var systemImage: String {
        switch self {
        case .connection: return "bolt.shield"
        case .appearance: return "paintbrush"
        case .protection: return "checkmark.shield"
        case .network: return "network"
        case .routing: return "point.3.connected.trianglepath.dotted"
        case .ai: return "sparkles"
        case .tor: return "globe.badge.chevron.backward"
        case .sharing: return "wifi.router"
        case .backup: return "externaldrive.badge.timemachine"
        case .sync: return "arrow.triangle.2.circlepath"
        case .diagnostics: return "stethoscope"
        case .advanced: return "gearshape.2"
        case .about: return "info.circle"
        }
    }

    func title(russian: Bool) -> String {
        switch self {
        case .connection: return russian ? "Подключение" : "Connection"
        case .appearance: return russian ? "Оформление и язык" : "Appearance and language"
        case .protection: return russian ? "Защита и реклама" : "Protection and ads"
        case .network: return russian ? "Сеть и DNS" : "Network and DNS"
        case .routing: return russian ? "Правила и маршруты" : "Rules and routing"
        case .ai: return russian ? "Нейросети" : "AI services"
        case .tor: return russian ? "Tor и мосты" : "Tor and bridges"
        case .sharing: return russian ? "Прокси и раздача VPN" : "Proxy and VPN sharing"
        case .backup: return russian ? "Резервные копии" : "Backup and restore"
        case .sync: return russian ? "Перенос и синхронизация" : "Transfer and sync"
        case .diagnostics: return russian ? "Диагностика" : "Diagnostics"
        case .advanced: return russian ? "Дополнительно" : "Advanced"
        case .about: return russian ? "О приложении" : "About"
        }
    }

    func hint(russian: Bool) -> String {
        switch self {
        case .connection: return russian ? "Автовыбор, пинг и поведение туннеля" : "Auto-select, ping and tunnel behavior"
        case .appearance: return russian ? "14 тем, прозрачность, размытие и язык" : "14 themes, transparency, blur and language"
        case .protection: return russian ? "IPv6, блокировка QUIC и реклама" : "IPv6, QUIC block and ad blocker"
        case .network: return russian ? "Маршрутизация, общий DNS и режим пинга" : "Routing, DNS and ping mode"
        case .routing: return russian ? "Домены Direct / Proxy / Block" : "Direct / Proxy / Block domain rules"
        case .ai: return russian ? "SmartDNS, ChatGPT, Gemini и Claude" : "SmartDNS, ChatGPT, Gemini and Claude"
        case .tor: return russian ? "Мосты и обход (в разработке для iOS)" : "Bridges (planned for iOS)"
        case .sharing: return russian ? "Локальный прокси в Wi-Fi сети" : "Local Wi-Fi proxy sharing"
        case .backup: return russian ? "Экспорт и восстановление AES-256-GCM" : "AES-256-GCM export and restore"
        case .sync: return russian ? "WebDAV и перенос по QR (скоро)" : "WebDAV and QR transfer (coming soon)"
        case .diagnostics: return russian ? "Журнал событий, GeoData и проверки" : "Event logs, GeoData and checks"
        case .advanced: return russian ? "TLS-фрагментация, MTU и Sniffing" : "TLS fragment, MTU and sniffing"
        case .about: return russian ? "Версия ядра Xray и лицензии" : "Xray core version and info"
        }
    }

    func matches(query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty { return true }
        let haystack = "\(title(russian: true)) \(title(russian: false)) \(hint(russian: true)) \(hint(russian: false)) \(rawValue)".lowercased()
        return trimmed.split(whereSeparator: \.isWhitespace).allSatisfy { haystack.contains($0) }
    }

    static func visible(for mode: AppUiMode) -> [SettingsCategory] {
        if mode.isSimple {
            return [.appearance, .protection, .backup, .diagnostics, .about]
        }
        return allCases
    }
}
