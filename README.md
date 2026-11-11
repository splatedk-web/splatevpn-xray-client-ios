# SplateVPN for iOS 🛡️

Нативный iOS-клиент **SplateVPN** (порт Android-клиента), построенный на **SwiftUI**, **NetworkExtension (`NEPacketTunnelProvider`)**, **HevSocks5Tunnel** и **XrayCore**.

---

## 📱 Архитектура проекта

Проект разделен на три изолированных и строго типизированных модуля:

```
SplateClientiOS/
├── project.yml                     # Декларативная спецификация XcodeGen (генератор .xcodeproj)
├── .github/workflows/build-ios.yml # Автоматическая облачная сборка .IPA через GitHub Actions (macOS)
│
├── SplateCore/                     # Общее ядро (Shared Framework)
│   ├── SplateConstants.swift       # Порты, встроенные пресеты (CIDR RU, Harvester, LTE)
│   ├── Models/
│   │   ├── ServerNode.swift        # Модель сервера (VLESS, VMess, Trojan, Shadowsocks)
│   │   ├── Subscription.swift      # Модель подписки
│   │   ├── VpnState.swift          # Статусы подключения и режимы маршрутизации
│   │   └── TrafficStats.swift      # Статистика байтов и скорости
│   ├── Parsers/
│   │   ├── NodeParser.swift        # Парсер ссылок vless://, vmess://, trojan://, ss://
│   │   └── SubscriptionParser.swift# Декодер base64-подписок и списков узлов
│   ├── Xray/
│   │   └── XrayConfigGenerator.swift # Генератор чистых JSON-конфигов для Xray Core
│   └── Storage/
│       └── AppGroupStorage.swift   # Межпроцессный обмен через App Groups (group.com.danieldk.splatevpn)
│
├── SplateVPNTunnel/                # Системное расширение туннеля (NetworkExtension)
│   ├── Info.plist                  # Декларация com.apple.networkextension.packet-tunnel
│   ├── SplateVPNTunnel.entitlements# Entitlements для packet-tunnel-provider и App Groups
│   └── PacketTunnelProvider.swift  # Обработчик виртуального TUN-адаптера и маршрутов
│
└── SplateVPN/                      # Основное приложение (SwiftUI 1:1 по дизайну Splate)
    ├── SplateVPNApp.swift          # Главный цикл приложения с Glass TabBar
    ├── Theme/
    │   └── SplateTheme.swift       # Фирменная тёмная палитра (#070B14, #00F0FF, стекломорфизм)
    ├── State/
    │   └── AppState.swift          # Реактивное управление состоянием, серверами и подписками
    ├── Tunnel/
    │   └── VpnTunnelController.swift # Мост к системному NETunnelProviderManager
    └── Views/
        ├── HomeScreen.swift        # Главный экран (Hero кнопка, статус, трафик, выбор узла)
        ├── ServersView.swift       # Список узлов, проверка пинга, добавление по ссылке
        ├── SubscriptionsView.swift # Предустановленные списки RU, автообновление
        ├── SettingsView.swift      # Выбор режима маршрутизации, DNS, Anti-DPI
        ├── QrScannerView.swift     # Нативный сканер QR-кодов на AVFoundation
        └── Components/
            └── GlassComponents.swift # Стеклянные карточки, индикаторы задержки, кнопки
```

---

## 🚀 Как скомпилировать .IPA через GitHub (Без Mac)

Поскольку компилятор iOS и Xcode работают только на macOS, мы настроили **GitHub Actions**, где проект компилируется на бесплатных серверах Apple Silicon от GitHub:

### Шаг 1. Создайте репозиторий на GitHub
1. Перейдите на [github.com/new](https://github.com/new) и создайте новый приватный или публичный репозиторий (например, `SplateClientiOS`).
2. В терминале вашего проекта свяжите локальную папку с репозиторием и отправьте код:
   ```powershell
   cd c:\Users\Daniel\AndroidStudioProjects\SplateClientiOS
   git add .
   git commit -m "Initial commit of SplateVPN iOS client"
   git branch -M main
   git remote add origin https://github.com/splatedk-web/splatevpn-xray-client-ios.git
   git push -u origin main
   ```

### Шаг 2. Автоматическая сборка
1. Откройте вкладку **Actions** в вашем репозитории на GitHub.
2. Workflow **`Build SplateVPN iOS (.IPA)`** запустится автоматически.
3. По завершении сборки (~2-3 минуты) внизу страницы запуска в блоке **Artifacts** скачайте архив `SplateVPN-iOS-Package`, внутри которого будет лежать готовый файл **`SplateVPN-unsigned.ipa`**.

---

## 📲 Как установить .IPA на iPhone с Windows

Для установки `.ipa` на реальный iPhone прямо из Windows:

### Способ 1. Через Sideloadly (Рекомендуемый, в 2 клика)
1. Скачайте и установите бесплатную программу [Sideloadly](https://sideloadly.io/) для Windows.
2. Подключите ваш iPhone к компьютеру через USB-кабель (разрешите «Доверять этому компьютеру» на экране телефона).
3. Запустите Sideloadly:
   * Перетащите скачанный файл `SplateVPN-unsigned.ipa` в окно программы.
   * В поле **Apple ID** введите ваш личный Apple ID (e-mail).
   * Нажмите кнопку **Start**.
4. После завершения на экране iPhone появится иконка **SplateVPN**.
5. На iPhone перейдите в: **Настройки -> Основные -> VPN и управление устройством**, нажмите на ваш Apple ID и выберите **«Доверять»**.

### Способ 2. Через AltStore (AltServer под Windows)
1. Установите [AltServer](https://altstore.io/) на Windows.
2. Подключите iPhone, нажмите «Install AltStore» -> Выберите ваш телефон.
3. Откройте AltStore на телефоне и установите `SplateVPN.ipa` через значок «+».
