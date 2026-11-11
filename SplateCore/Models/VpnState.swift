import Foundation

public enum VpnStatus: String, Codable {
    case disconnected
    case connecting
    case connected
    case disconnecting
    case failed

    public var title: String {
        switch self {
        case .disconnected: return "Отключено"
        case .connecting: return "Подключение..."
        case .connected: return "Защищено"
        case .disconnecting: return "Отключение..."
        case .failed: return "Ошибка подключения"
        }
    }
}

public enum RoutingMode: String, Codable, CaseIterable {
    case global = "global"
    case bypassRu = "bypass_ru"
    case directRu = "direct_ru"

    public var title: String {
        switch self {
        case .global: return "Маршрутизировать всё"
        case .bypassRu: return "Обход блокировок (РФ напрямую)"
        case .directRu: return "Только через VPN (Белые списки)"
        }
    }
}
