<h1 align="center">SplateVPN — VPN-клиент для iOS на Xray</h1>

<p align="center">
  iOS VPN с поддержкой VLESS / Reality, VMess, Trojan и Shadowsocks.<br />
  Импорт подписок, автоматическая маршрутизация, DNS-настройки и поддержка NetworkExtension.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.0%2B-black?style=flat-square&logo=apple" alt="iOS 17.0 и новее" />
  <img src="https://img.shields.io/badge/App-1.2.8-orange?style=flat-square" alt="Версия в исходниках: 1.2.8" />
  <img src="https://img.shields.io/badge/Xray--core-26.10.31-blue?style=flat-square" alt="Xray-core 26.10.31" />
  <img src="https://img.shields.io/badge/UI-SwiftUI-blueviolet?style=flat-square" alt="SwiftUI" />
  <a href="https://github.com/splatedk-web/splatevpn-xray-client-ios"><img src="https://img.shields.io/github/stars/splatedk-web/splatevpn-xray-client-ios?style=flat-square&amp;logo=github&amp;label=Stars" alt="GitHub Stars" /></a>
</p>

<p align="center">
  <a href="https://github.com/splatedk-web/splatevpn-xray-client-ios/releases">Скачать IPA</a> ·
  <a href="#возможности">Возможности</a> ·
  <a href="#сборка-из-исходников">Сборка из исходников</a> ·
  <a href="https://github.com/splatedk-web/splatevpn-xray-client-ios/issues">Сообщить об ошибке</a>
</p>

> Проект находится в активной разработке. Версия в исходниках — **1.2.8**; доступность сборок проверяйте в разделе Releases и GitHub Actions. Для подключения нужен рабочий сервер или подписка.

## О приложении

**SplateVPN (Splate VPN) для iOS** — клиент для подключения iOS-устройств к совместимым прокси-серверам через системный интерфейс NetworkExtension (`NEPacketTunnelProvider`). Сетевую конфигурацию обрабатывает Xray-core, передачу пакетов из системного TUN-интерфейса — hev-socks5-tunnel.

Это клиент, а не собственная сеть VPN-серверов. Можно импортировать свою конфигурацию или подписку. Встроенные списки используют сторонние публичные источники: доступность, скорость и условия работы таких серверов зависят от их владельцев.

**English:** SplateVPN for iOS is an open-source VPN client powered by Xray-core and hev-socks5-tunnel built on SwiftUI and Apple NetworkExtension framework. It supports VLESS / Reality, VMess, Trojan, Shadowsocks, subscription import, rule-based routing and configurable DNS. Bring a compatible server or subscription; the app does not operate its own VPN server network.

## Возможности

### Подключение и серверы

- Протоколы **VLESS, VMess, Trojan и Shadowsocks**, поддержка Reality и Vision для совместимых конфигураций.
- Транспорты TCP, WebSocket, gRPC, XHTTP и другие варианты, поддерживаемые ядром Xray.
- Импорт ссылок и подписок, вставка из буфера обмена и встроенное сканирование QR-кодов через Vision / AVFoundation.
- Поиск, группировка, сортировка и обновление подписок вручную или по расписанию.
- Проверка задержки (ping) и доступности серверов.
- Автоматический выбор оптимального сервера из списка.

### Маршрутизация и сеть

- **Умный маршрут (Обход РФ)**: разделение прямого трафика и проксирования по правилам доменов и геобаз (доступ к российским сервисам и банкам напрямую).
- **Весь трафик (Global)**: направление всего сетевого трафика через зашифрованный туннель.
- **Только через VPN (Белый список)**: подключение только к заданным ресурсам через VPN.
- Сетевая изоляция через Apple NetworkExtension: чистая интеграция с системным интерфейсом без сторонних фоновых демонов.

### DNS и защита

- Настройки DNS over HTTPS (DoH) с поддержкой Cloudflare, Google, Quad9 и AdGuard DNS.
- Фильтрация рекламы и трекеров на уровне сетевых запросов.
- Anti-DPI: фрагментация TLS Client Hello для защиты от блокировок по сигнатурам протоколов.

## Сборка из исходников

Стек проекта: Swift **5.9+**, SwiftUI, Apple **NetworkExtension**, **XcodeGen**, Xray-core и hev-socks5-tunnel.

Для локальной сборки требуется macOS с Xcode 15+ и установленный `xcodegen`:

```bash
git clone https://github.com/splatedk-web/splatevpn-xray-client-ios.git
cd splatevpn-xray-client-ios

# Генерация проекта Xcode
xcodegen generate

# Сборка
xcodebuild -project SplateVPN.xcodeproj -scheme SplateVPN -configuration Release -destination 'generic/platform=iOS'
```

Для сборки без macOS настроен автоматический CI/CD во вкладке **Actions** на базе GitHub-раннеров `macos-14`, создающий готовые пакеты приложения.

## Обратная связь

Создайте [Issue](https://github.com/splatedk-web/splatevpn-xray-client-ios/issues), укажите версию приложения и iOS, шаги воспроизведения и приложите скриншот или журнал диагностики. Перед публикацией удалите из отчёта ключи, UUID, ссылки приватных подписок и другие личные данные.

Предложения и pull request приветствуются.

## Лицензии

Для собственного кода SplateVPN используется [Apache License 2.0](LICENSE). У сторонних компонентов свои условия (Xray-core, hev-socks5-tunnel, lwIP).

## История звёзд

<a href="https://www.star-history.com/#splatedk-web/splatevpn-xray-client-ios&amp;Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=splatedk-web/splatevpn-xray-client-ios&amp;type=Date&amp;theme=dark" />
    <img src="https://api.star-history.com/svg?repos=splatedk-web/splatevpn-xray-client-ios&amp;type=Date" alt="График роста звёзд SplateVPN iOS на GitHub" />
  </picture>
</a>
