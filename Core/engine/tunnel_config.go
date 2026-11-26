package engine

import (
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strings"

	"splatevpn.dev/ios/core/imports"
)

// TunnelOptions configures routing, DNS, sniffing, ad-blocking, fragmentation, and statistics for iOS PacketTunnel.
type TunnelOptions struct {
	MTU                 int
	RoutingMode         string // "global", "bypass_lan", "smart_ru"
	DNSServer           string // e.g. "1.1.1.1" or "https://1.1.1.1/dns-query"
	Sniffing            bool
	BlockQUIC           bool
	EnableAdBlock       bool
	EnableTLSFragment   bool
	EnableIPv6          bool
	EnableAiSmartDNS    bool
	AiDNSProvider       string
	ShareLanProxy       bool
	LanProxyPort        int
	LanProxyUser        string
	LanProxyPass        string
	EnableStats         bool
	AssetsDir           string
	CustomDirectDomains []string
	CustomProxyDomains  []string
	CustomBlockDomains  []string
}

func DefaultTunnelOptions() TunnelOptions {
	return TunnelOptions{
		MTU:               1400,
		RoutingMode:       "bypass_lan",
		DNSServer:         "1.1.1.1",
		Sniffing:          true,
		BlockQUIC:         true,
		EnableAdBlock:     false,
		EnableTLSFragment: false,
		EnableIPv6:        false,
		EnableStats:       true,
	}
}

func marshalObject(v object) (string, error) {
	encoded, err := json.Marshal(v)
	if err != nil {
		return "", fmt.Errorf("encode Xray configuration: %w", err)
	}
	return string(encoded), nil
}

// PacketTunnelConfigurationWithOptions builds an iOS TUN Xray configuration with DNS,
// routing rules, and optional traffic statistics.
func PacketTunnelConfigurationWithOptions(link, fullConfigJSON string, opts TunnelOptions) (string, error) {
	if opts.MTU < 1280 || opts.MTU > 9000 {
		return "", errors.New("invalid packet tunnel MTU")
	}

	inbound := object{
		"tag":      "packet-tunnel",
		"protocol": "tun",
		"settings": object{"name": "splate-tunnel", "mtu": opts.MTU},
	}
	if opts.Sniffing {
		inbound["sniffing"] = object{
			"enabled":      true,
			"destOverride": []string{"http", "tls", "quic"},
			"routeOnly":    false,
		}
	}

	outbounds, serverHost, err := buildOutbounds(link, fullConfigJSON)
	if err != nil {
		return "", err
	}
	if opts.EnableTLSFragment && len(outbounds) > 0 {
		outbounds = attachTLSFragment(outbounds)
	}

	inbounds := []object{inbound}
	if opts.ShareLanProxy {
		port := opts.LanProxyPort
		if port < 1024 || port > 65535 {
			port = 10809
		}
		mixedSettings := object{"udp": true}
		if opts.LanProxyUser != "" || opts.LanProxyPass != "" {
			mixedSettings["auth"] = "password"
			mixedSettings["accounts"] = []object{{"user": opts.LanProxyUser, "pass": opts.LanProxyPass}}
		} else {
			mixedSettings["auth"] = "noauth"
		}
		inbounds = append(inbounds, object{
			"tag":      "lan-mixed",
			"listen":   "0.0.0.0",
			"port":     port,
			"protocol": "mixed",
			"settings": mixedSettings,
		})
	}

	root := object{
		"log":       object{"loglevel": "warning"},
		"dns":       buildDNS(opts, serverHost),
		"inbounds":  inbounds,
		"outbounds": outbounds,
		"routing":   buildRouting(opts),
	}

	if opts.EnableStats {
		root["stats"] = object{}
		root["policy"] = object{
			"system": object{
				"statsOutboundUplink":   true,
				"statsOutboundDownlink": true,
			},
		}
	}

	encoded, err := json.Marshal(root)
	if err != nil {
		return "", fmt.Errorf("encode Xray configuration: %w", err)
	}
	return string(encoded), nil
}

func buildOutbounds(link, fullConfigJSON string) ([]object, string, error) {
	var outbounds []object
	var serverHost string

	if strings.TrimSpace(fullConfigJSON) != "" {
		var parsed map[string]any
		if err := json.Unmarshal([]byte(fullConfigJSON), &parsed); err != nil {
			return nil, "", fmt.Errorf("invalid full Xray JSON profile: %w", err)
		}
		rawList, ok := parsed["outbounds"].([]any)
		if !ok || len(rawList) == 0 {
			return nil, "", errors.New("full Xray JSON profile has no outbounds")
		}
		hasDirect, hasBlock := false, false
		for i, item := range rawList {
			ob, ok := item.(map[string]any)
			if !ok {
				continue
			}
			if i == 0 {
				ob["tag"] = "proxy"
			}
			tag, _ := ob["tag"].(string)
			if tag == "direct" {
				hasDirect = true
			}
			if tag == "block" {
				hasBlock = true
			}
			outbounds = append(outbounds, ob)
		}
		if len(outbounds) == 0 {
			return nil, "", errors.New("full Xray JSON profile has no valid outbound objects")
		}
		if !hasDirect {
			outbounds = append(outbounds, object{"tag": "direct", "protocol": "freedom"})
		}
		if !hasBlock {
			outbounds = append(outbounds, object{"tag": "block", "protocol": "blackhole"})
		}
		return outbounds, serverHost, nil
	}

	server, err := imports.ParseServerLink(link)
	if err != nil {
		return nil, "", err
	}
	proxy, err := outbound(server)
	if err != nil {
		return nil, "", err
	}
	if net.ParseIP(server.Address) == nil {
		serverHost = server.Address
	}
	outbounds = []object{
		proxy,
		{"tag": "direct", "protocol": "freedom"},
		{"tag": "block", "protocol": "blackhole"},
	}
	return outbounds, serverHost, nil
}

func buildDNS(opts TunnelOptions, serverHost string) object {
	dnsAddr := strings.TrimSpace(opts.DNSServer)
	if dnsAddr == "" {
		dnsAddr = "1.1.1.1"
	}
	hosts := object{}
	servers := []any{}
	if serverHost != "" {
		servers = append(servers, object{
			"address": "localhost",
			"domains": []string{"full:" + serverHost},
		})
	}
	if opts.EnableAiSmartDNS {
		provider := resolveSmartDNSProvider(opts.AiDNSProvider)
		hosts[provider.Host] = provider.BootstrapIPv4
		servers = append(servers, object{
			"address":      provider.DoHURL(),
			"skipFallback": true,
			"domains":      aiSmartDNSDomains,
		})
	}
	servers = append(servers, dnsAddr)
	queryStrategy := "UseIPv4"
	if opts.EnableIPv6 {
		queryStrategy = "UseIP"
	}
	dnsObj := object{
		"servers":       servers,
		"queryStrategy": queryStrategy,
	}
	if opts.EnableAiSmartDNS {
		dnsObj["hosts"] = hosts
		dnsObj["disableFallbackIfMatch"] = true
	}
	return dnsObj
}

func attachTLSFragment(outbounds []object) []object {
	primary := outbounds[0]
	stream, ok := primary["streamSettings"].(object)
	if !ok {
		stream = object{}
	}
	sockopt, ok := stream["sockopt"].(object)
	if !ok {
		sockopt = object{}
	}
	sockopt["dialerProxy"] = "fragment"
	stream["sockopt"] = sockopt
	primary["streamSettings"] = stream
	outbounds[0] = primary

	outbounds = append(outbounds, object{
		"tag":      "fragment",
		"protocol": "freedom",
		"settings": object{
			"fragment": object{
				"packets":  "tlshello",
				"length":   "100-200",
				"interval": "10-20",
			},
		},
	})
	return outbounds
}

func buildRouting(opts TunnelOptions) object {
	rules := []object{}
	mode := strings.ToLower(strings.TrimSpace(opts.RoutingMode))
	if mode == "" {
		mode = "bypass_lan"
	}

	if cleaned := cleanDomainList(opts.CustomBlockDomains); len(cleaned) > 0 {
		rules = append(rules, object{
			"type":        "field",
			"domain":      cleaned,
			"outboundTag": "block",
		})
	}
	if cleaned := cleanDomainList(opts.CustomDirectDomains); len(cleaned) > 0 {
		rules = append(rules, object{
			"type":        "field",
			"domain":      cleaned,
			"outboundTag": "direct",
		})
	}
	if cleaned := cleanDomainList(opts.CustomProxyDomains); len(cleaned) > 0 {
		rules = append(rules, object{
			"type":        "field",
			"domain":      cleaned,
			"outboundTag": "proxy",
		})
	}

	if opts.EnableAiSmartDNS {
		provider := resolveSmartDNSProvider(opts.AiDNSProvider)
		rules = append(rules, object{
			"type":        "field",
			"domain":      append([]string{"full:" + provider.Host}, aiSmartDNSDomains...),
			"outboundTag": "direct",
		})
	}

	if opts.EnableAdBlock && hasGeoFile(opts.AssetsDir, "geosite.dat") {
		rules = append(rules, object{
			"type":        "field",
			"domain":      []string{"geosite:category-ads-all"},
			"outboundTag": "block",
		})
	}

	if opts.BlockQUIC {
		rules = append(rules, object{
			"type":        "field",
			"network":     "udp",
			"port":        "443",
			"outboundTag": "block",
		})
	}

	if mode != "global" {
		if hasGeoFile(opts.AssetsDir, "geoip.dat") {
			rules = append(rules, object{
				"type":        "field",
				"ip":          []string{"geoip:private"},
				"outboundTag": "direct",
			})
		} else {
			rules = append(rules, object{
				"type": "field",
				"ip": []string{
					"127.0.0.0/8", "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16",
					"169.254.0.0/16", "::1/128", "fc00::/7", "fe80::/10",
				},
				"outboundTag": "direct",
			})
		}
	}

	if mode == "smart_ru" {
		if hasGeoFile(opts.AssetsDir, "geosite.dat") {
			rules = append(rules, object{
				"type":        "field",
				"domain":      []string{"geosite:category-ru", "geosite:private"},
				"outboundTag": "direct",
			})
		}
		if hasGeoFile(opts.AssetsDir, "geoip.dat") {
			rules = append(rules, object{
				"type":        "field",
				"ip":          []string{"geoip:ru"},
				"outboundTag": "direct",
			})
		}
	}

	rules = append(rules, object{
		"type":        "field",
		"network":     "tcp,udp",
		"outboundTag": "proxy",
	})

	return object{
		"domainStrategy": "IPIfNonMatch",
		"rules":          rules,
	}
}

func hasGeoFile(assetsDir, filename string) bool {
	if strings.TrimSpace(assetsDir) == "" {
		return false
	}
	info, err := os.Stat(filepath.Join(assetsDir, filename))
	return err == nil && !info.IsDir() && info.Size() > 0
}

func cleanDomainList(raw []string) []string {
	out := make([]string, 0, len(raw))
	for _, entry := range raw {
		trimmed := strings.TrimSpace(entry)
		if trimmed == "" || strings.HasPrefix(trimmed, "#") {
			continue
		}
		if !strings.Contains(trimmed, ":") {
			trimmed = "domain:" + trimmed
		}
		out = append(out, trimmed)
	}
	return out
}
