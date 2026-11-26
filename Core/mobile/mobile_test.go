package mobile

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestMobileBridgeParsingAndConfig(t *testing.T) {
	if CoreVersion() == "" {
		t.Fatal("CoreVersion returned empty string")
	}

	subJSON, err := ParseSubscriptionLink("happ://add/https://example.com/sub")
	if err != nil {
		t.Fatal(err)
	}
	var sub subscriptionLinkDTO
	if err := json.Unmarshal([]byte(subJSON), &sub); err != nil || sub.URL != "https://example.com/sub" {
		t.Fatalf("unexpected subscription DTO: %s (%v)", subJSON, err)
	}

	link := "vless://c2663a17-a284-49ab-b4a6-adb560d12090@remote.example:443?security=tls&flow=xtls-rprx-vision#Main"
	profileJSON, err := ParseServerLink(link)
	if err != nil {
		t.Fatal(err)
	}
	var profile serverProfileDTO
	if err := json.Unmarshal([]byte(profileJSON), &profile); err != nil || profile.Protocol != "vless" || profile.Name != "Main" {
		t.Fatalf("unexpected profile DTO: %s (%v)", profileJSON, err)
	}

	listJSON, err := ParseServerSubscription(link + "\ntrojan://pass@two.example:443#Two")
	if err != nil {
		t.Fatal(err)
	}
	var list []serverProfileDTO
	if err := json.Unmarshal([]byte(listJSON), &list); err != nil || len(list) != 2 {
		t.Fatalf("expected 2 profiles in list JSON, got %d (%v)", len(list), err)
	}

	optsJSON := `{"mtu":1400,"routingMode":"bypass_lan","dnsServer":"1.1.1.1","sniffing":true,"blockQuic":true,"enableTlsFragment":true,"customDirectDomains":["example.ru"]}`
	cfg, err := BuildTunnelConfigJSON(link, "", optsJSON)
	if err != nil || !strings.Contains(cfg, `"packet-tunnel"`) || !strings.Contains(cfg, `"fragment"`) || !strings.Contains(cfg, `"domain:example.ru"`) {
		t.Fatalf("BuildTunnelConfigJSON failed: %v", err)
	}

	eng := NewTunnelEngine()
	if eng.IsRunning() {
		t.Fatal("new TunnelEngine should not be running")
	}
	if stats := eng.TrafficStatsJSON(); stats != `{"uplink":0,"downlink":0}` {
		t.Fatalf("unexpected initial stats: %s", stats)
	}
}
