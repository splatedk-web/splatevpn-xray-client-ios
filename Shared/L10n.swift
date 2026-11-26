import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case ru = "ru"
    case en = "en"
    case fa = "fa"
    case zhHans = "zh-Hans"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .ru: return "Русский"
        case .en: return "English"
        case .fa: return "فارسی"
        case .zhHans: return "简体中文"
        }
    }

    public var layoutDirection: LayoutDirection {
        self == .fa ? .rightToLeft : .leftToRight
    }
}

public struct L10n {
    public let lang: AppLanguage

    public init(code: String) {
        self.lang = AppLanguage(rawValue: code) ?? .ru
    }

    private func t(ru: String, en: String, fa: String, zh: String) -> String {
        switch lang {
        case .ru: return ru
        case .en: return en
        case .fa: return fa
        case .zhHans: return zh
        }
    }

    // Tabs
    public var tabHome: String { t(ru: "Главная", en: "Home", fa: "خانه", zh: "主页") }
    public var tabServers: String { t(ru: "Серверы", en: "Servers", fa: "سرورها", zh: "服务器") }
    public var tabSettings: String { t(ru: "Настройки", en: "Settings", fa: "تنظیمات", zh: "设置") }

    // Connection
    public var connect: String { t(ru: "Подключить", en: "Connect", fa: "اتصال", zh: "连接") }
    public var disconnect: String { t(ru: "Отключить", en: "Disconnect", fa: "قطع اتصال", zh: "断开") }
    public var statusConnected: String { t(ru: "Подключено", en: "Connected", fa: "متصل", zh: "已连接") }
    public var statusConnecting: String { t(ru: "Подключение…", en: "Connecting…", fa: "در حال اتصال…", zh: "正在连接…") }
    public var statusDisconnecting: String { t(ru: "Отключение…", en: "Disconnecting…", fa: "در حال قطع…", zh: "正在断开…") }
    public var statusReasserting: String { t(ru: "Переподключение…", en: "Reconnecting…", fa: "اتصال مجدد…", zh: "正在重连…") }
    public var statusDisconnected: String { t(ru: "Отключено", en: "Disconnected", fa: "قطع شده", zh: "未连接") }
    public var statusInvalid: String { t(ru: "Не настроено", en: "Not configured", fa: "تنظیم نشده", zh: "未配置") }
    public var uploaded: String { t(ru: "Отправлено", en: "Uploaded", fa: "ارسالی", zh: "上传") }
    public var downloaded: String { t(ru: "Получено", en: "Downloaded", fa: "دریافتی", zh: "下载") }
    public var noServerSelected: String {
        t(
            ru: "Нет выбранного сервера. Добавьте ссылку или подписку во вкладке «Серверы».",
            en: "No server selected. Add a link or subscription in the Servers tab.",
            fa: "سروری انتخاب نشده است. از بخش سرورها لینک یا اشتراک اضافه کنید.",
            zh: "未选择服务器。请在“服务器”标签页添加链接或订阅。"
        )
    }
    public var autoSelectFastest: String { t(ru: "Выбрать лучший", en: "Auto-select fastest", fa: "انتخاب سریع‌ترین", zh: "自动选择最快节点") }

    // Servers
    public var subscriptions: String { t(ru: "Подписки", en: "Subscriptions", fa: "اشتراک‌ها", zh: "订阅") }
    public var nodes: String { t(ru: "Узлы", en: "Nodes", fa: "گره‌ها", zh: "节点") }
    public var pingAll: String { t(ru: "Пинг всех", en: "Ping all", fa: "پینگ همه", zh: "全部测速") }
    public var scanQR: String { t(ru: "Сканировать QR", en: "Scan QR", fa: "اسکن QR", zh: "扫描二维码") }
    public var importTitle: String { t(ru: "Импорт", en: "Import", fa: "ورود", zh: "导入") }
    public var pasteClipboard: String { t(ru: "Вставить из буфера", en: "Paste from clipboard", fa: "چسباندن از کلیپ‌بورد", zh: "从剪贴板粘贴") }
    public var cancel: String { t(ru: "Отмена", en: "Cancel", fa: "لغو", zh: "取消") }
    public var add: String { t(ru: "Добавить", en: "Add", fa: "افزودن", zh: "添加") }

    // Routing
    public func routingTitle(_ mode: RoutingMode) -> String {
        switch mode {
        case .smartRU: return t(ru: "Умный маршрут", en: "Smart routing", fa: "مسیریابی هوشمند", zh: "智能分流")
        case .global: return t(ru: "Весь трафик", en: "All traffic (Global)", fa: "تمام ترافیک", zh: "全局代理")
        case .whitelist: return t(ru: "Только через VPN", en: "VPN only (Whitelist)", fa: "فقط لیست سفید", zh: "仅白名单代理")
        }
    }

    public func pingModeTitle(_ mode: PingMode) -> String {
        switch mode {
        case .realDelay: return t(ru: "Реальная задержка (HTTP)", en: "Real Delay (HTTP)", fa: "تأخیر واقعی (HTTP)", zh: "真实延迟 (HTTP)")
        case .tcp: return t(ru: "TCP рукопожатие", en: "TCP Handshake", fa: "اتصال TCP", zh: "TCP 握手")
        }
    }

    // Settings
    public var routingSection: String { t(ru: "Маршрутизация", en: "Routing", fa: "مسیریابی", zh: "路由") }
    public var networkDnsSection: String { t(ru: "Сеть и DNS", en: "Network & DNS", fa: "شبکه و DNS", zh: "网络与 DNS") }
    public var protectionSection: String { t(ru: "Защита и обход", en: "Protection & Anti-DPI", fa: "حفاظت و ضد فیلتر", zh: "保护与抗封锁") }
    public var diagnosticsSection: String { t(ru: "Диагностика", en: "Diagnostics", fa: "عیب‌یابی", zh: "诊断") }
    public var appearanceSection: String { t(ru: "Язык и интерфейс", en: "Language & Interface", fa: "زبان و رابط", zh: "语言与界面") }
    public var aboutSection: String { t(ru: "О приложении", en: "About", fa: "درباره", zh: "关于") }
    public var customRules: String { t(ru: "Пользовательские правила", en: "Custom domain rules", fa: "قوانین دامنه سفارشی", zh: "自定义域名规则") }
    public var adBlocker: String { t(ru: "Блокировщик рекламы (GeoSite)", en: "Ad blocker (GeoSite)", fa: "مسدودکننده تبلیغات", zh: "广告拦截 (GeoSite)") }
    public var tlsFragment: String { t(ru: "TLS-фрагментация (Anti-DPI)", en: "TLS Fragmentation (Anti-DPI)", fa: "تکه‌تکه‌سازی TLS", zh: "TLS 分片 (抗封锁)") }
    public var enableIpv6: String { t(ru: "Поддержка IPv6", en: "IPv6 Support", fa: "پشتیبانی IPv6", zh: "启用 IPv6") }
    public var logsTitle: String { t(ru: "Журнал событий", en: "Event Logs", fa: "گزارش رویدادها", zh: "运行日志") }
    public var language: String { t(ru: "Язык", en: "Language", fa: "زبان", zh: "语言") }
    public var coreVersion: String { t(ru: "Ядро Xray", en: "Xray Core", fa: "هسته Xray", zh: "Xray 核心") }

    // Onboarding
    public var onboardingTitle: String { t(ru: "Добро пожаловать в SplateVPN", en: "Welcome to SplateVPN", fa: "به SplateVPN خوش آمدید", zh: "欢迎使用 SplateVPN") }
    public var onboardingSubtitle: String {
        t(
            ru: "Быстрый и надёжный клиент на базе Xray-core для iOS. Выберите язык и режим маршрутизации.",
            en: "Fast and reliable Xray-core client for iOS. Choose your language and routing mode.",
            fa: "کلاینت سریع و مطمئن مبتنی بر Xray-core برای iOS. زبان و حالت مسیریابی را انتخاب کنید.",
            zh: "基于 Xray-core 的快速可靠 iOS 客户端。请选择语言和分流模式。"
        )
    }
    public var startUsing: String { t(ru: "Начать работу", en: "Get Started", fa: "شروع کنید", zh: "开始使用") }
}
