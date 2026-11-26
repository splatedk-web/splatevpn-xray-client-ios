package imports

import (
	"encoding/base64"
	"strings"
	"testing"
)

func TestSubscriptionLink(t *testing.T) {
	const vector = "incy://crypt1/AAECAwQFBgcICQoLNyIQL3rDwRZqnyoD8pGKSLXP6o8NdSXQVSSALNbbUyIr__tWGFUexdIfKvvmDnuDGbmBvuppfNef6aKNZUwOm4c-Sg"
	const direct = "https://example.com/sub?token=a+b%2Fc"
	cases := map[string]string{
		"  " + direct:             direct,
		"Happ://add/" + direct:    direct,
		"incy://import/" + direct: direct,
		"incy://add/https%3A%2F%2Fexample.com%2Fsub%3Ftoken%3Da+b%252Fc": direct,
		vector: "https://sub.example.com/test-vector",
	}
	for raw, want := range cases {
		got, err := ParseSubscriptionLink(raw)
		if err != nil || got.URL != want {
			t.Fatalf("ParseSubscriptionLink(%q) = %q, %v; want %q", raw, got.URL, err, want)
		}
	}
	for _, raw := range []string{"https://", "file:///tmp/sub", "happ://crypt3/abc", "incy://crypt1/AA", vector[:len(vector)-2] + "AA"} {
		if _, err := ParseSubscriptionLink(raw); err == nil {
			t.Fatalf("ParseSubscriptionLink(%q) succeeded", raw)
		}
	}
}

func TestDecodeSubscriptionBody(t *testing.T) {
	const body = "vless://test@example.com:443#Server\ntrojan://pass@example.com:443"
	encoded := base64.StdEncoding.EncodeToString([]byte(body))
	for _, raw := range []string{
		" \uFEFF" + body,
		encoded,
		"data:text/plain;base64," + encoded,
		base64.RawURLEncoding.EncodeToString([]byte(encoded)),
		encoded[:8] + "\n " + encoded[8:],
	} {
		decoded, err := DecodeSubscriptionBody(raw)
		if err != nil || decoded != body {
			t.Fatalf("DecodeSubscriptionBody(%q) = %q, %v", raw, decoded, err)
		}
	}
	if _, err := DecodeSubscriptionBody(strings.Repeat("x", maxSubscriptionSize+1)); err == nil {
		t.Fatal("oversized subscription was accepted")
	}
}

func TestVLESSProfile(t *testing.T) {
	description := base64.RawURLEncoding.EncodeToString([]byte("**Primary server**"))
	raw := "vless://c2663a17-a284-49ab-b4a6-adb560d12090@[2001:db8::1]:8443/svc" +
		"?type=gun&flow=xtls-rprx-vision&publicKey=a+b%2Fc%3D&sid=ab&serverName=example.com#Main%20server?serverDescription=" + description
	profile, err := ParseVLESS(raw)
	if err != nil {
		t.Fatal(err)
	}
	if profile.Name != "Main server" || profile.Description != "Primary server" ||
		profile.Address != "2001:db8::1" || profile.Port != 8443 || profile.Network != "grpc" ||
		profile.Security != "reality" || profile.PublicKey != "a+b/c=" || profile.SNI != "example.com" ||
		profile.Path != "svc" || profile.Fingerprint != "chrome" || profile.ShortID != "ab" ||
		profile.Flow != "xtls-rprx-vision" || profile.Encryption != "none" {
		t.Fatalf("unexpected VLESS profile: %+v", profile)
	}
}

func TestVLESSXHTTPOptions(t *testing.T) {
	profile, err := ParseVLESS("vless://test@example.com?type=splithttp&path=proxy+path&extra=%7B%22mode%22%3A%22stream-up%22%2C%22xPaddingBytes%22%3A123%7D")
	if err != nil {
		t.Fatal(err)
	}
	if profile.Port != 443 || profile.Security != "tls" || profile.Network != "xhttp" ||
		profile.Path != "/proxy+path" || profile.Mode != "stream-up" || profile.Padding != "123" {
		t.Fatalf("unexpected VLESS profile: %+v", profile)
	}
}

func TestVLESSRejectsInvalidEndpoints(t *testing.T) {
	for _, raw := range []string{
		"vless://example.com", "vless://test@", "vless://test@example.com:65536",
		"vless://test@example.com:", "vless://test@example.com?type=xdrive",
	} {
		if _, err := ParseVLESS(raw); err == nil {
			t.Fatalf("ParseVLESS(%q) succeeded", raw)
		}
	}
}

func TestVLESSSubscription(t *testing.T) {
	const raw = "vless://bad@server.example:0\nvless://test@one.example#One\n" +
		"trojan://other@other.example\nvless://test@two.example:8443#Two"
	profiles, err := ParseVLESSSubscription(base64.StdEncoding.EncodeToString([]byte(raw)))
	if err != nil || len(profiles) != 2 {
		t.Fatalf("expected two VLESS profiles, got %d, %v", len(profiles), err)
	}
	if profiles[0].Name != "One" || profiles[1].Name != "Two" || profiles[1].Port != 8443 {
		t.Fatalf("unexpected profiles: %+v", profiles)
	}
	if _, err := ParseVLESSSubscription(strings.Repeat("vless://test@one.example\n", 20_001)); err == nil {
		t.Fatal("subscription profile count limit was not enforced")
	}
}

func TestMixedServerSubscription(t *testing.T) {
	credentials := base64.RawURLEncoding.EncodeToString([]byte("user:p+a/ss"))
	raw := "vless://test@one.example#One\n" +
		"trojan://p+a%2Fss@two.example:8443/ignored?type=grpc&serviceName=svc#Two+words\n" +
		"socks5://" + credentials + "@[2001:db8::2]\n" +
		"socks://u%40name:p%3Ass+word@three.example:1081#Three"
	profiles, err := ParseServerSubscription(base64.StdEncoding.EncodeToString([]byte(raw)))
	if err != nil || len(profiles) != 4 {
		t.Fatalf("expected four profiles, got %d, %v", len(profiles), err)
	}
	for i, protocol := range []Protocol{VLESS, Trojan, SOCKS5, SOCKS5} {
		if profiles[i].Protocol != protocol {
			t.Fatalf("profile %d protocol = %s, want %s", i, profiles[i].Protocol, protocol)
		}
	}
	trojan := profiles[1]
	if trojan.Password != "p+a/ss" || trojan.Security != "tls" || trojan.SNI != "two.example" ||
		trojan.Path != "svc" || trojan.Name != "Two words" || trojan.Port != 8443 {
		t.Fatalf("unexpected Trojan profile: %+v", trojan)
	}
	socks := profiles[2]
	if socks.Username != "user" || socks.Password != "p+a/ss" || socks.Port != 1080 ||
		socks.Address != "2001:db8::2" || socks.Network != "tcp" || socks.Security != "none" {
		t.Fatalf("unexpected SOCKS profile: %+v", socks)
	}
	if profiles[3].Username != "u@name" || profiles[3].Password != "p:ss+word" {
		t.Fatalf("unexpected SOCKS credentials: %+v", profiles[3])
	}
}

func TestServerLinkWithoutOptionalOptions(t *testing.T) {
	socks, err := ParseServerLink("socks5://proxy.example")
	if err != nil || socks.Username != "" || socks.Password != "" || socks.Port != 1080 {
		t.Fatalf("unexpected anonymous SOCKS profile: %+v, %v", socks, err)
	}
	trojan, err := ParseServerLink("trojan://secret@proxy.example?pbk=public+key")
	if err != nil || trojan.Security != "reality" || trojan.PublicKey != "public+key" || trojan.Port != 443 {
		t.Fatalf("unexpected Trojan REALITY profile: %+v, %v", trojan, err)
	}
	for _, raw := range []string{"socks://proxy.example:0", "trojan://secret@proxy.example:65536", "https://proxy.example"} {
		if _, err := ParseServerLink(raw); err == nil {
			t.Fatalf("ParseServerLink(%q) succeeded", raw)
		}
	}
}
