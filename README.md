<h1 align="center">SplateVPN — VPN-клиент для iOS на Xray</h1>

<p align="center">
  iOS VPN с поддержкой VLESS / Reality, VMess, Trojan, Shadowsocks, Hysteria 2 и SOCKS5.<br />
  Импорт подписок, 14 тем с Liquid Glass, AI SmartDNS, маршрутизация, WebDAV, виджеты и NetworkExtension.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-16.0%2B-black?style=flat-square&logo=apple" alt="iOS 16.0 и новее" />
  <img src="https://img.shields.io/badge/App-1.3.0-orange?style=flat-square" alt="Версия: 1.3.0" />
  <img src="https://img.shields.io/badge/Xray--core-26.11.9-blue?style=flat-square" alt="Xray-core 26.11.9" />
  <img src="https://img.shields.io/badge/UI-SwiftUI-blueviolet?style=flat-square" alt="SwiftUI" />
  <a href="https://github.com/splatedk-web/splatevpn-xray-client-ios"><img src="https://img.shields.io/github/stars/splatedk-web/splatevpn-xray-client-ios?style=flat-square&amp;logo=github&amp;label=Stars" alt="GitHub Stars" /></a>
</p>

<p align="center">
  <a href="https://github.com/splatedk-web/splatevpn-xray-client-ios/actions">Скачать IPA (Actions)</a> ·
  <a href="https://github.com/splatedk-web/splatevpn-xray-client-ios/releases">Releases</a> ·
  <a href="#возможности">Возможности</a> ·
  <a href="#сборка-из-исходников">Сборка из исходников</a> ·
  <a href="https://github.com/splatedk-web/splatevpn-xray-client-ios/issues">Сообщить об ошибке</a>
</p>

> Проект находится в активной разработке. Для подключения нужен рабочий сервер или подписка. Готовые неподписанные `.ipa` собираются автоматически во вкладке **Actions**.

## О приложении

**SplateVPN для iOS** — нативный клиент для iPhone и iPad на базе SwiftUI, Apple NetworkExtension (`NEPacketTunnelProvider`) и встроенного Go-ядра `xray-core` (`SplateCore.xcframework`), работающего напрямую с системным `utun`-интерфейсом с контролем лимита памяти NetworkExtension.

Это клиент, а не собственная сеть VPN-серверов. Вы можете импортировать свои серверы или подписки из буфера, по ссылке, через QR-код или deep link (`happ://`, `incy://`, `vless://`, `vmess://`, `trojan://`, `ss://`, `hy2://`, `socks5://`).

**English:** SplateVPN for iOS is an open-source VPN client powered by embedded Go `xray-core` (`SplateCore.xcframework`), SwiftUI, and Apple `NEPacketTunnelProvider`. It supports VLESS / Reality, VMess, Trojan, Shadowsocks, Hysteria 2, SOCKS5, Clash YAML, full Xray JSON profiles, AI SmartDNS, 14 Liquid Glass themes, encrypted Android-compatible backups, WebDAV sync, and WidgetKit / Control Center widgets.

## Возможности

### Подключение и серверы

- Протоколы **VLESS (Reality / Vision), VMess, Trojan, Shadowsocks, Hysteria 2 (Salamander + Port Hopping), SOCKS5**.
- Транспорты **TCP, WebSocket, gRPC, HTTPUpgrade, XHTTP** и полные **Xray JSON** / **Clash YAML** профили.
- Импорт подписок (`http/https`, `happ://add/`, `incy://add/`, `incy://import/`, `incy://crypt1/`), разбор заголовков `Subscription-Userinfo` и `Profile-Title`, вставка из буфера и сканер QR-кодов (`AVFoundation`).
- Вкладки **Узлы / Подписки / Личные**, редактор узла, генерация QR для шаринга, быстрый выбор узла с Главной.
- Пакетный пинг (**Real Delay HTTP** через in-memory Xray и **TCP**) + автовыбор самого быстрого сервера.

### Маршрутизация, DNS и защита

- Режимы маршрутизации: **Обход локальной сети (LAN)**, **Умный маршрут (РФ напрямую по GeoIP/GeoSite)**, **Весь трафик (Global)**.
- Пользовательские правила доменов (**Direct / Proxy / Block**).
- **AI SmartDNS** (9 провайдеров: DNS-AI, GeoHide RU/EU, MALW, Zapret DNS, Dagami, WLRus, Geodema) для ChatGPT, Gemini, Claude, Copilot, Perplexity, Grok и Cursor.
- Блокировка рекламы (`geosite:category-ads-all`), блокировка QUIC (UDP 443), IPv6, Sniffing и **TLS-фрагментация (Anti-DPI)**.
- **Локальный Mixed HTTP/SOCKS5 прокси в Wi-Fi LAN** с опциональной авторизацией.

### Интерфейс, темы и инструменты

- **14 тем 1-в-1 с Android** (`Dark`, `AMOLED`, `Light`, `System`, `Cyberpunk`, `Winter`, `Winter Light`, `Red`, `Aurora`, `Sunset`, `Ocean`, `Sakura`, `Pony`, `Winx`) с иллюстрациями, настройкой прозрачности и размытия **Liquid Glass**, плавающим доком и режимами **Простой / Расширенный**.
- Локализация на 4 языка: **Русский, English, فارسی (RTL), 简体中文**.
- **Резервные копии AES-256-GCM** (совместимые с Android `BackupCipher`) и синхронизация через **WebDAV**.
- **Диагностика:** Speedtest (Cloudflare), проверка доступности сервисов (YouTube, Telegram, ChatGPT, Gemini, DNS), карточка Egress IP/локации и общий журнал событий App + PacketTunnel.
- **WidgetKit** (виджеты на экран «Домой») и переключатель в **Пункте управления (iOS 18+)**.

## Сборка из исходников

Стек: Go (`xray-core` + `gomobile`), SwiftUI, Apple `NetworkExtension`, `WidgetKit`, `XcodeGen`.

```bash
git clone https://github.com/splatedk-web/splatevpn-xray-client-ios.git
cd splatevpn-xray-client-ios

# 1. Собрать Go-ядро (SplateCore.xcframework)
bash Scripts/build-core-xcframework.sh

# 2. Сгенерировать Xcode-проект
xcodegen generate
```

Для сборки без macOS используйте вкладку **Actions** → workflow **iOS Build & IPA** (`macos-15`), который автоматически собирает и публикует `SplateVPN-unsigned.ipa` в артефактах.

## Обратная связь

Создайте [Issue](https://github.com/splatedk-web/splatevpn-xray-client-ios/issues), укажите версию приложения и iOS, шаги воспроизведения и приложите журнал диагностики (предварительно удалив ключи, UUID и приватные ссылки подписок).

## Лицензии

Для собственного кода SplateVPN используется Apache License 2.0. У сторонних компонентов свои условия (Xray-core и др.).

## История звёзд

<a href="https://www.star-history.com/#splatedk-web/splatevpn-xray-client-ios&amp;Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=splatedk-web/splatevpn-xray-client-ios&amp;type=Date&amp;theme=dark" />
    <img src="https://api.star-history.com/svg?repos=splatedk-web/splatevpn-xray-client-ios&amp;type=Date" alt="График роста звёзд SplateVPN iOS на GitHub" />
  </picture>
</a>
