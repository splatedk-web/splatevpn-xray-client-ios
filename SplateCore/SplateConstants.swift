import Foundation

public enum SplateConstants {
    public static let appGroupId = "group.com.danieldk.splatevpn"
    public static let tunnelBundleId = "com.danieldk.splatevpn.tunnel"
    public static let repositoryUrl = "https://github.com/splatedk-web/splatevpn-xray-client"
    public static let version = "1.2.8"

    // Ports
    public static let xraySocksPort: UInt16 = 10808
    public static let byedpiSocksPort: UInt16 = 10810
    public static let dnsCheckSocksPort: UInt16 = 10818

    // Addresses
    public static let loopbackAddress = "127.0.0.1"
    public static let tunIpv4Address = "172.19.0.1"
    public static let tunIpv4Netmask = "255.255.0.0"
    public static let tunDnsAddress = "172.19.0.2"

    // Built-in Subscription Presets
    public static let presetWhiteCidrId = "preset_white_cidr"
    public static let presetWhiteCidrName = "Белый список (CIDR RU)"
    public static let presetWhiteCidrUrl = "https://raw.githubusercontent.com/igareck/vpn-configs-for-russia/refs/heads/main/WHITE-CIDR-RU-all.txt"

    public static let presetHarvesterId = "preset_harvester"
    public static let presetHarvesterName = "Harvester (Рабочие узлы)"
    public static let presetHarvesterUrl = "https://raw.githubusercontent.com/luxxuria/harvester/refs/heads/main/ping_tested.txt"

    public static let presetUniversalId = "preset_white_universal"
    public static let presetUniversalName = "Белый список (Universal)"
    public static let presetUniversalUrl = "https://raw.githubusercontent.com/zieng2/wl/refs/heads/main/vless_universal.txt"

    public static let presetLteId = "preset_white_lte_checked"
    public static let presetLteName = "Белый список (LTE Checked)"
    public static let presetLteUrl = "https://raw.githubusercontent.com/hussaroff/lte-universal-checked/main/whitelist.txt"

    public static let presetSponsorId = "preset_sponsor"
    public static let presetSponsorName = "🌐 WTPN 🔐"
    public static let presetSponsorUrl = "https://sub.wt419.site/wt/splatevpn"
}
