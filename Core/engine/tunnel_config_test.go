package engine

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"testing"

	"github.com/xtls/xray-core/core"
)

func TestXrayLoadsVMessAndShadowsocksConfigs(t *testing.T) {
	vmessJSON := `{"v":"2","ps":"VMess","add":"vmess.example.com","port":443,"id":"c2663a17-a284-49ab-b4a6-adb560d12090","net":"ws","path":"/ws","host":"cdn.example.com","tls":"tls"}`
	vmessLink := "vmess://" + base64.StdEncoding.EncodeToString([]byte(vmessJSON))
	ssLink := "ss://" + base64.RawURLEncoding.EncodeToString([]byte("aes-256-gcm:secretpass")) + "@ss.example.com:8388#SS"

	for _, link := range []string{vmessLink, ssLink} {
		cfg, err := PacketTunnelConfigurationWithOptions(link, "", DefaultTunnelOptions())
		if err != nil {
			t.Fatalf("build config for %q: %v", link, err)
		}
		if _, err := core.LoadConfig("json", bytes.NewBufferString(cfg)); err != nil {
			t.Fatalf("Xray rejected config for %q: %v", link, err)
		}
	}
}

func TestXrayLoadsFullJSONProfileWithOptions(t *testing.T) {
	fullJSON := `{
		"outbounds": [{
			"tag": "custom-proxy",
			"protocol": "vless",
			"settings": {
				"vnext": [{
					"address": "example.com",
					"port": 443,
					"users": [{"id": "c2663a17-a284-49ab-b4a6-adb560d12090", "encryption": "none"}]
				}]
			},
			"streamSettings": {"network": "tcp", "security": "tls"}
		}]
	}`
	opts := DefaultTunnelOptions()
	opts.RoutingMode = "global"
	opts.DNSServer = "https://1.1.1.1/dns-query"
	cfg, err := PacketTunnelConfigurationWithOptions("", fullJSON, opts)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := core.LoadConfig("json", bytes.NewBufferString(cfg)); err != nil {
		t.Fatalf("Xray rejected full JSON profile config: %v", err)
	}
}

func TestTrafficStatsTracksLiveTraffic(t *testing.T) {
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

	clientPort := availablePort(t)
	rawCfg := object{
		"log":   object{"loglevel": "none"},
		"stats": object{},
		"policy": object{
			"system": object{
				"statsOutboundUplink":   true,
				"statsOutboundDownlink": true,
			},
		},
		"inbounds": []object{{
			"listen": "127.0.0.1", "port": clientPort, "protocol": "socks",
			"settings": object{"auth": "noauth"},
		}},
		"outbounds": []object{{
			"tag": "proxy", "protocol": "socks",
			"settings": object{"servers": []object{{"address": "127.0.0.1", "port": upstreamPort}}, "version": "5"},
		}},
	}
	encoded, err := json.Marshal(rawCfg)
	if err != nil {
		t.Fatal(err)
	}

	eng := NewEngine()
	if eng.IsRunning() {
		t.Fatal("engine reported running before Start")
	}
	if err := eng.Start(string(encoded)); err != nil {
		t.Fatal(err)
	}
	defer func() { _ = eng.Stop() }()

	if !eng.IsRunning() {
		t.Fatal("engine reported not running after Start")
	}
	assertResponseThroughProxy(t, clientPort, target.URL)

	up, down := eng.TrafficStats()
	if up <= 0 || down <= 0 {
		t.Fatalf("expected non-zero traffic stats, got uplink=%d downlink=%d", up, down)
	}
}
