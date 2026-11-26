package imports

import (
	"errors"
	"net"
	"strconv"
	"strings"

	"gopkg.in/yaml.v2"
)

type clashConfig struct {
	Proxies []map[string]any `yaml:"proxies"`
}

func parseClashYAML(body string) ([]ServerProfile, error) {
	const maxProfiles = 20_000
	var doc clashConfig
	if err := yaml.Unmarshal([]byte(body), &doc); err != nil || len(doc.Proxies) == 0 {
		return nil, nil
	}

	var profiles []ServerProfile
	for _, raw := range doc.Proxies {
		p, ok := parseClashProxy(raw)
		if !ok {
			continue
		}
		if len(profiles) == maxProfiles {
			return nil, errors.New("too many subscription profiles")
		}
		profiles = append(profiles, p)
	}
	return profiles, nil
}

func parseClashProxy(m map[string]any) (ServerProfile, bool) {
	rawType := strings.ToLower(strings.TrimSpace(yamlStr(m["type"])))
	protocol, ok := normalizeJSONProtocol(rawType)
	if !ok {
		return ServerProfile{}, false
	}

	address := strings.TrimSpace(yamlStr(m["server"]))
	port := yamlInt(m["port"])
	if address == "" || port < 1 || port > 65535 {
		return ServerProfile{}, false
	}

	name := strings.TrimSpace(yamlStr(m["name"]))
	if name == "" {
		name = net.JoinHostPort(address, strconv.Itoa(port))
	}

	network := normalizeNetwork(firstNonEmpty(yamlStr(m["network"]), "tcp"))
	security := "none"
	if yamlBool(m["tls"]) || protocol == Trojan {
		security = "tls"
	}

	var publicKey, shortID string
	if ro := yamlMap(m["reality-opts"]); ro != nil {
		publicKey = yamlStr(ro["public-key"])
		shortID = yamlStr(ro["short-id"])
		if publicKey != "" {
			security = "reality"
		}
	}

	sni := firstNonEmpty(yamlStr(m["servername"]), yamlStr(m["sni"]))
	fp := firstNonEmpty(yamlStr(m["client-fingerprint"]), "chrome")
	var path, host string

	switch network {
	case "ws":
		if opts := yamlMap(m["ws-opts"]); opts != nil {
			path = yamlStr(opts["path"])
			if headers := yamlMap(opts["headers"]); headers != nil {
				host = yamlStr(headers["Host"])
			}
		}
		if path == "" {
			path = "/"
		}
	case "grpc":
		if opts := yamlMap(m["grpc-opts"]); opts != nil {
			path = yamlStr(opts["grpc-service-name"])
		}
	}

	profile := ServerProfile{
		Protocol:    protocol,
		Name:        name,
		Address:     address,
		Port:        port,
		Network:     network,
		Security:    security,
		SNI:         sni,
		Fingerprint: fp,
		PublicKey:   publicKey,
		ShortID:     shortID,
		Path:        path,
		Host:        host,
		Mode:        "auto",
	}

	switch protocol {
	case VLESS:
		profile.ID = yamlStr(m["uuid"])
		profile.Flow = yamlStr(m["flow"])
		profile.Encryption = "none"
	case VMess:
		profile.ID = yamlStr(m["uuid"])
		profile.Encryption = firstNonEmpty(yamlStr(m["cipher"]), "auto")
	case Trojan:
		profile.Password = yamlStr(m["password"])
		if profile.SNI == "" {
			profile.SNI = address
		}
	case Shadowsocks:
		profile.Encryption = firstNonEmpty(yamlStr(m["cipher"]), "aes-256-gcm")
		profile.Password = yamlStr(m["password"])
		profile.Network = "tcp"
		profile.Security = "none"
	case SOCKS5:
		profile.Username = yamlStr(m["username"])
		profile.Password = yamlStr(m["password"])
		profile.Network = "tcp"
		profile.Security = "none"
	}

	return profile, true
}

func yamlStr(v any) string {
	switch x := v.(type) {
	case string:
		return x
	case int:
		return strconv.Itoa(x)
	default:
		return ""
	}
}

func yamlInt(v any) int {
	switch x := v.(type) {
	case int:
		return x
	case int64:
		return int(x)
	case float64:
		return int(x)
	case string:
		n, _ := strconv.Atoi(strings.TrimSpace(x))
		return n
	default:
		return 0
	}
}

func yamlBool(v any) bool {
	switch x := v.(type) {
	case bool:
		return x
	case string:
		l := strings.ToLower(strings.TrimSpace(x))
		return l == "true" || l == "1"
	default:
		return false
	}
}

func yamlMap(v any) map[string]any {
	switch x := v.(type) {
	case map[string]any:
		return x
	case map[any]any:
		out := make(map[string]any, len(x))
		for k, val := range x {
			if ks, ok := k.(string); ok {
				out[ks] = val
			}
		}
		return out
	default:
		return nil
	}
}
