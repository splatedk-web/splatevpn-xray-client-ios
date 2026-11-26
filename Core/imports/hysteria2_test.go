package imports

import "testing"

func TestHysteria2ParsingAndHopping(t *testing.T) {
	raw := "hy2://my%2Bpass@hy2.example.com:20000-20010,20020/?sni=cdn.example.com&obfs=salamander&obfs-password=obfspw&hop-interval=45s#Hy2%20Fast"
	p, err := ParseServerLink(raw)
	if err != nil {
		t.Fatal(err)
	}
	if p.Protocol != Hysteria2 || p.Name != "Hy2 Fast" || p.Address != "hy2.example.com" ||
		p.Port != 20000 || p.Password != "my+pass" || p.SNI != "cdn.example.com" ||
		p.Obfs != "salamander" || p.ObfsPassword != "obfspw" ||
		p.HopPorts != "20000-20010,20020" || p.HopInterval != 45 {
		t.Fatalf("unexpected Hysteria2 profile: %+v", p)
	}

	// insecure=1 without pinSHA256 must be rejected (matches Android policy).
	if _, err := ParseServerLink("hy2://pw@hy2.example.com:443?insecure=1"); err == nil {
		t.Fatal("insecure Hysteria2 without pinSHA256 was accepted")
	}
}
