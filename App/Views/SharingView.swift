import Darwin
import SwiftUI

struct SharingView: View {
    @EnvironmentObject private var vpn: VPNManager

    var body: some View {
        Form {
            Section {
                Toggle("Раздавать Mixed прокси в Wi-Fi LAN", isOn: Binding(
                    get: { vpn.state.settings.shareLanProxy },
                    set: { v in vpn.updateSettings { $0.shareLanProxy = v } }
                ))
            } footer: {
                Text("Поднимает локальный HTTP + SOCKS5 прокси внутри туннеля. Другие устройства в вашей Wi-Fi сети смогут указать IP и порт iPhone в настройках прокси.")
            }

            Section("Параметры прокси") {
                LabeledContent("Адрес в Wi-Fi", value: "\(localWiFiIPv4() ?? "—"):\(vpn.state.settings.lanProxyPort)")

                Stepper("Порт: \(vpn.state.settings.lanProxyPort)", value: Binding(
                    get: { vpn.state.settings.lanProxyPort },
                    set: { v in vpn.updateSettings { $0.lanProxyPort = v } }
                ), in: 1024...65000, step: 1)

                TextField("Логин (необязательно)", text: Binding(
                    get: { vpn.state.settings.lanProxyUser },
                    set: { v in vpn.updateSettings { $0.lanProxyUser = v } }
                ))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                SecureField("Пароль (необязательно)", text: Binding(
                    get: { vpn.state.settings.lanProxyPass },
                    set: { v in vpn.updateSettings { $0.lanProxyPass = v } }
                ))
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Прокси и раздача VPN")
    }

    private func localWiFiIPv4() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let current = ptr {
            let addr = current.pointee
            let name = String(cString: addr.ifa_name)
            if name == "en0", addr.ifa_addr.pointee.sa_family == UInt8(AF_INET) {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(addr.ifa_addr, socklen_t(addr.ifa_addr.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
                return String(cString: host)
            }
            ptr = addr.ifa_next
        }
        return nil
    }
}
