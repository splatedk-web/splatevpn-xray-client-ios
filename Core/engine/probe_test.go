package engine

import (
	"bytes"
	"fmt"
	"testing"

	"github.com/xtls/xray-core/core"
)

func TestTLSFragmentAndCustomRoutingConfigLoads(t *testing.T) {
	link := "vless://c2663a17-a284-49ab-b4a6-adb560d12090@remote.example:443?security=tls&flow=xtls-rprx-vision"
	opts := DefaultTunnelOptions()
	opts.EnableTLSFragment = true
	opts.EnableIPv6 = true
	opts.CustomDirectDomains = []string{"yandex.ru", "full:vk.com"}
	opts.CustomProxyDomains = []string{"openai.com"}
	opts.CustomBlockDomains = []string{"ads.example.com"}

	cfg, err := PacketTunnelConfigurationWithOptions(link, "", opts)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := core.LoadConfig("json", bytes.NewBufferString(cfg)); err != nil {
		t.Fatalf("Xray rejected fragmented+custom routing config: %v", err)
	}
}

func TestXrayLoadsHysteria2ConfigWithSalamanderAndHopping(t *testing.T) {
	link := "hy2://pass123@hy2.example.com:20000-20010/?sni=cdn.example.com&obfs=salamander&obfs-password=obfssecret&hop-interval=30s#Hy2"
	cfg, err := PacketTunnelConfigurationWithOptions(link, "", DefaultTunnelOptions())
	if err != nil {
		t.Fatal(err)
	}
	if _, err := core.LoadConfig("json", bytes.NewBufferString(cfg)); err != nil {
		t.Fatalf("Xray rejected Hysteria2 config: %v", err)
	}
}

func TestXrayLoadsAiSmartDNSAndLanMixedProxy(t *testing.T) {
	link := "vless://c2663a17-a284-49ab-b4a6-adb560d12090@remote.example:443?security=tls"
	opts := DefaultTunnelOptions()
	opts.EnableAiSmartDNS = true
	opts.AiDNSProvider = "geohide"
	opts.ShareLanProxy = true
	opts.LanProxyPort = 10809
	opts.LanProxyUser = "splate"
	opts.LanProxyPass = "secret123"

	cfg, err := PacketTunnelConfigurationWithOptions(link, "", opts)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := core.LoadConfig("json", bytes.NewBufferString(cfg)); err != nil {
		t.Fatalf("Xray rejected AI SmartDNS + LAN Mixed Proxy config: %v", err)
	}
}

func TestMeasureURLDelayLiveLoopback(t *testing.T) {
	target := newTestTarget()
	defer target.Close()

	upstream := NewEngine()
	upstreamPort := availablePort(t)
	upstreamConfig := fmt.Sprintf(`{
		"log":{"loglevel":"none"},
		"inbounds":[{"listen":"127.0.0.1","port":%d,"protocol":"socks","settings":{"auth":"noauth"}}],
		"outbounds":[{"protocol":"freedom"}]
	}`, upstreamPort)
	if err := upstream.Start(upstreamConfig); err != nil {
		t.Fatal(err)
	}
	defer func() { _ = upstream.Stop() }()

	link := fmt.Sprintf("socks5://127.0.0.1:%d", upstreamPort)
	tcpMs, err := MeasureLinkTCPDelay(link, 3000)
	if err != nil || tcpMs < 1 {
		t.Fatalf("MeasureLinkTCPDelay failed: ms=%d err=%v", tcpMs, err)
	}

	urlMs, err := MeasureURLDelay(link, "", target.URL, 5000)
	if err != nil || urlMs < 1 {
		t.Fatalf("MeasureURLDelay failed: ms=%d err=%v", urlMs, err)
	}
}
