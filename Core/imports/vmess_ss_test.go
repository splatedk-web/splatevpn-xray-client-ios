package imports

import (
	"encoding/base64"
	"testing"
)

func TestVMessLinkParsing(t *testing.T) {
	payload := `{"v":"2","ps":"Frankfurt VMess","add":"vmess.example.com","port":"443","id":"c2663a17-a284-49ab-b4a6-adb560d12090","net":"ws","host":"cdn.example.com","path":"ws/v2","tls":"tls","scy":"aes-128-gcm","fp":"firefox"}`
	raw := "vmess://" + base64.StdEncoding.EncodeToString([]byte(payload))

	profile, err := ParseServerLink(raw)
	if err != nil {
		t.Fatal(err)
	}
	if profile.Protocol != VMess || profile.Name != "Frankfurt VMess" || profile.Address != "vmess.example.com" ||
		profile.Port != 443 || profile.ID != "c2663a17-a284-49ab-b4a6-adb560d12090" ||
		profile.Network != "ws" || profile.Security != "tls" || profile.SNI != "cdn.example.com" ||
		profile.Path != "/ws/v2" || profile.Encryption != "aes-128-gcm" || profile.Fingerprint != "firefox" {
		t.Fatalf("unexpected VMess profile: %+v", profile)
	}

	// Invalid port must fail.
	bad := "vmess://" + base64.StdEncoding.EncodeToString([]byte(`{"add":"vmess.example.com","port":99999}`))
	if _, err := ParseServerLink(bad); err == nil {
		t.Fatal("VMess link with out-of-range port was accepted")
	}
}

func TestShadowsocksLinkParsing(t *testing.T) {
	sip002 := "ss://" + base64.RawURLEncoding.EncodeToString([]byte("aes-256-gcm:p+a/ss:word")) + "@ss.example.com:8388#SS%20One"
	p1, err := ParseServerLink(sip002)
	if err != nil {
		t.Fatal(err)
	}
	if p1.Protocol != Shadowsocks || p1.Name != "SS One" || p1.Address != "ss.example.com" || p1.Port != 8388 ||
		p1.Encryption != "aes-256-gcm" || p1.Password != "p+a/ss:word" {
		t.Fatalf("unexpected SIP002 profile: %+v", p1)
	}

	legacy := "ss://" + base64.StdEncoding.EncodeToString([]byte("chacha20-ietf-poly1305:secret@203.0.113.10:8443")) + "#Legacy"
	p2, err := ParseServerLink(legacy)
	if err != nil {
		t.Fatal(err)
	}
	if p2.Protocol != Shadowsocks || p2.Name != "Legacy" || p2.Address != "203.0.113.10" || p2.Port != 8443 ||
		p2.Encryption != "chacha20-ietf-poly1305" || p2.Password != "secret" {
		t.Fatalf("unexpected legacy SS profile: %+v", p2)
	}

	plain := "ss://2022-blake3-aes-128-gcm:my%2Bpass@[2001:db8::9]:9000#Plain"
	p3, err := ParseServerLink(plain)
	if err != nil {
		t.Fatal(err)
	}
	if p3.Address != "2001:db8::9" || p3.Port != 9000 || p3.Encryption != "2022-blake3-aes-128-gcm" || p3.Password != "my+pass" {
		t.Fatalf("unexpected plain SS profile: %+v", p3)
	}
}

func TestJSONSubscriptionParsing(t *testing.T) {
	raw := `{
		"remarks": "Full Xray Profile",
		"dns": {"servers": ["1.1.1.1"]},
		"outbounds": [
			{
				"tag": "proxy",
				"protocol": "vless",
				"settings": {
					"vnext": [{
						"address": "xray.example.com",
						"port": 443,
						"users": [{"id": "c2663a17-a284-49ab-b4a6-adb560d12090", "encryption": "none"}]
					}]
				},
				"streamSettings": {
					"network": "xhttp",
					"security": "reality",
					"realitySettings": {"serverName": "example.com", "publicKey": "pub123", "shortId": "ab"}
				}
			},
			{"tag": "direct", "protocol": "freedom"}
		]
	}`

	profiles, err := ParseServerSubscription(raw)
	if err != nil {
		t.Fatal(err)
	}
	if len(profiles) != 1 {
		t.Fatalf("expected 1 profile, got %d", len(profiles))
	}
	p := profiles[0]
	if p.Protocol != VLESS || p.Name != "Full Xray Profile" || p.Address != "xray.example.com" ||
		p.Port != 443 || p.Network != "xhttp" || p.Security != "reality" || p.PublicKey != "pub123" ||
		p.FullConfigJSON == "" {
		t.Fatalf("unexpected JSON profile: %+v", p)
	}
}
