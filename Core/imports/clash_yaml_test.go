package imports

import "testing"

func TestClashYAMLSubscriptionParsing(t *testing.T) {
	yamlSub := `
proxies:
  - name: "DE Reality"
    type: vless
    server: de.example.com
    port: 443
    uuid: c2663a17-a284-49ab-b4a6-adb560d12090
    network: tcp
    tls: true
    servername: microsoft.com
    flow: xtls-rprx-vision
    reality-opts:
      public-key: pubkey123
      short-id: ab12
  - name: "NL SS"
    type: ss
    server: nl.example.com
    port: 8388
    cipher: aes-256-gcm
    password: secret
`
	profiles, err := ParseServerSubscription(yamlSub)
	if err != nil {
		t.Fatal(err)
	}
	if len(profiles) != 2 {
		t.Fatalf("expected 2 Clash profiles, got %d", len(profiles))
	}
	if profiles[0].Protocol != VLESS || profiles[0].Security != "reality" || profiles[0].PublicKey != "pubkey123" || profiles[0].SNI != "microsoft.com" {
		t.Fatalf("unexpected Clash VLESS profile: %+v", profiles[0])
	}
	if profiles[1].Protocol != Shadowsocks || profiles[1].Encryption != "aes-256-gcm" || profiles[1].Password != "secret" {
		t.Fatalf("unexpected Clash SS profile: %+v", profiles[1])
	}
}
