package engine

import (
	"bytes"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"
	"time"

	"github.com/xtls/xray-core/core"
)

func TestXrayLoadsGeneratedConfigurations(t *testing.T) {
	for _, link := range []string{
		"vless://c2663a17-a284-49ab-b4a6-adb560d12090@remote.example:443?security=tls&flow=xtls-rprx-vision",
		"vless://c2663a17-a284-49ab-b4a6-adb560d12090@remote.example:443?type=xhttp&path=%2Fproxy&host=cdn.example&mode=stream-up",
		"trojan://pass@remote.example:443?type=ws&path=%2Fproxy&host=cdn.example",
		"socks5://user:pass@127.0.0.1:1080",
	} {
		config, err := SOCKSConfiguration(link, 1081)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := core.LoadConfig("json", bytes.NewBufferString(config)); err != nil {
			t.Fatalf("Xray rejected settings for fixture %q: %v", link, err)
		}
	}
}

func TestXrayLoadsPacketTunnelConfiguration(t *testing.T) {
	const link = "socks5://user:pass@127.0.0.1:1080"
	config, err := packetTunnelConfiguration(link, 1500)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := core.LoadConfig("json", bytes.NewBufferString(config)); err != nil {
		t.Fatal(err)
	}
	if _, err := packetTunnelConfiguration(link, 1200); err == nil {
		t.Fatal("an MTU below the IPv6 minimum was accepted")
	}
}

func TestEngineProxiesLiveTrafficAndRestarts(t *testing.T) {
	target := newTestTarget()
	defer target.Close()

	// A second local Xray instance acts as an upstream SOCKS server.
	upstream := NewEngine()
	upstreamPort := availablePort(t)
	upstreamConfig := fmt.Sprintf(`{
		"log":{"loglevel":"none"},
		"inbounds":[{"listen":"127.0.0.1","port":%d,"protocol":"socks","settings":{"auth":"password","accounts":[{"user":"fixture","pass":"test"}]}}],
		"outbounds":[{"protocol":"freedom"}]
	}`, upstreamPort)
	if err := upstream.Start(upstreamConfig); err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := upstream.Stop(); err != nil {
			t.Error(err)
		}
	}()

	clientPort := availablePort(t)
	config, err := SOCKSConfiguration(fmt.Sprintf("socks5://fixture:test@127.0.0.1:%d", upstreamPort), clientPort)
	if err != nil {
		t.Fatal(err)
	}
	engine := NewEngine()
	t.Cleanup(func() {
		if err := engine.Stop(); err != nil {
			t.Error(err)
		}
	})
	if err := engine.Start("{"); err == nil {
		t.Fatal("invalid configuration started successfully")
	}
	for range 2 {
		if err := engine.Start(config); err != nil {
			t.Fatal(err)
		}
		if err := engine.Start(config); err == nil {
			t.Fatal("a second start replaced the running instance")
		}
		assertResponseThroughProxy(t, clientPort, target.URL)
		if err := engine.Stop(); err != nil {
			t.Fatal(err)
		}
	}
}

func TestImportedVLESSProfileProxiesLiveTraffic(t *testing.T) {
	const id = "c2663a17-a284-49ab-b4a6-adb560d12090"
	target := newTestTarget()
	defer target.Close()

	server := NewEngine()
	serverPort := availablePort(t)
	targetPort := target.Listener.Addr().(*net.TCPAddr).Port
	// Allow only the loopback HTTP fixture through Xray's VLESS private-IP rule.
	serverConfig := fmt.Sprintf(`{
		"log":{"loglevel":"none"},
		"inbounds":[{"listen":"127.0.0.1","port":%d,"protocol":"vless","settings":{"clients":[{"id":"%s"}],"decryption":"none"}}],
		"outbounds":[{"protocol":"freedom","settings":{"finalRules":[{"action":"allow","network":"tcp","ip":["127.0.0.1"],"port":%d}]}}]
	}`, serverPort, id, targetPort)
	if err := server.Start(serverConfig); err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := server.Stop(); err != nil {
			t.Error(err)
		}
	}()

	clientPort := availablePort(t)
	link := fmt.Sprintf("vless://%s@127.0.0.1:%d?type=tcp&security=none#Local", id, serverPort)
	config, err := SOCKSConfiguration(link, clientPort)
	if err != nil {
		t.Fatal(err)
	}
	client := NewEngine()
	if err := client.Start(config); err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := client.Stop(); err != nil {
			t.Error(err)
		}
	}()
	assertResponseThroughProxy(t, clientPort, target.URL)
}

func newTestTarget() *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(response http.ResponseWriter, _ *http.Request) {
		_, _ = io.WriteString(response, "SplateVPN Xray integration")
	}))
}

func availablePort(t *testing.T) int {
	t.Helper()
	listener, err := net.Listen("tcp4", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	port := listener.Addr().(*net.TCPAddr).Port
	if err := listener.Close(); err != nil {
		t.Fatal(err)
	}
	return port
}

func assertResponseThroughProxy(t *testing.T, port int, target string) {
	t.Helper()
	proxy := &url.URL{Scheme: "socks5", Host: fmt.Sprintf("127.0.0.1:%d", port)}
	transport := &http.Transport{Proxy: http.ProxyURL(proxy)}
	defer transport.CloseIdleConnections()
	client := &http.Client{Transport: transport, Timeout: 5 * time.Second}
	response, err := client.Get(target)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	body, err := io.ReadAll(response.Body)
	if err != nil || response.StatusCode != 200 || string(body) != "SplateVPN Xray integration" {
		t.Fatalf("unexpected proxied response: status %d, body %q, error %v", response.StatusCode, body, err)
	}
}
