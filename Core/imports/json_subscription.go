package imports

import (
	"encoding/json"
	"errors"
	"net"
	"strconv"
	"strings"
)

func parseJSONSubscription(jsonText string) ([]ServerProfile, error) {
	const maxProfiles = 20_000

	var root any
	if err := json.Unmarshal([]byte(jsonText), &root); err != nil {
		return nil, nil
	}

	var entries []map[string]any
	switch v := root.(type) {
	case []any:
		for _, item := range v {
			if obj, ok := item.(map[string]any); ok {
				entries = append(entries, obj)
			}
		}
	case map[string]any:
		entries = []map[string]any{v}
	default:
		return nil, nil
	}

	var profiles []ServerProfile
	for _, entry := range entries {
		outbounds := sliceOfObjects(entry["outbounds"])
		hasXrayOutbounds := false
		for _, ob := range outbounds {
			if stringVal(ob["protocol"]) != "" {
				hasXrayOutbounds = true
				break
			}
		}
		fullConfig := hasXrayOutbounds && (entry["inbounds"] != nil || entry["routing"] != nil || entry["dns"] != nil)

		var candidates []map[string]any
		switch {
		case fullConfig:
			if first := firstSupportedOutbound(outbounds); first != nil {
				candidates = []map[string]any{first}
			}
		case len(outbounds) > 0:
			candidates = outbounds
		case len(sliceOfObjects(entry["servers"])) > 0:
			candidates = sliceOfObjects(entry["servers"])
		case len(sliceOfObjects(entry["proxies"])) > 0:
			candidates = sliceOfObjects(entry["proxies"])
		default:
			candidates = []map[string]any{entry}
		}

		configName := firstNonEmpty(stringVal(entry["remarks"]), stringVal(entry["name"]), stringVal(entry["profile-title"]))
		for _, candidate := range candidates {
			fullJSON := ""
			if fullConfig {
				if encoded, err := json.Marshal(entry); err == nil {
					fullJSON = string(encoded)
				}
			} else if hasXrayOutbounds {
				cloned := shallowCloneMap(entry)
				reordered := make([]map[string]any, 0, len(outbounds))
				reordered = append(reordered, candidate)
				for _, ob := range outbounds {
					if &ob != &candidate && !sameMapRef(ob, candidate) {
						reordered = append(reordered, ob)
					}
				}
				cloned["outbounds"] = reordered
				if encoded, err := json.Marshal(cloned); err == nil {
					fullJSON = string(encoded)
				}
			} else if stringVal(candidate["protocol"]) != "" && (candidate["settings"] != nil || candidate["streamSettings"] != nil) {
				if encoded, err := json.Marshal(map[string]any{"outbounds": []map[string]any{candidate}}); err == nil {
					fullJSON = string(encoded)
				}
			}

			profile, ok := parseJSONOutbound(candidate, configName, fullJSON)
			if !ok {
				continue
			}
			if len(profiles) == maxProfiles {
				return nil, errors.New("too many subscription profiles")
			}
			profiles = append(profiles, profile)
		}
	}
	return profiles, nil
}

func firstSupportedOutbound(outbounds []map[string]any) map[string]any {
	for _, ob := range outbounds {
		if _, ok := normalizeJSONProtocol(firstNonEmpty(stringVal(ob["protocol"]), stringVal(ob["type"]))); ok {
			return ob
		}
	}
	return nil
}

func normalizeJSONProtocol(raw string) (Protocol, bool) {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "vless":
		return VLESS, true
	case "vmess":
		return VMess, true
	case "trojan":
		return Trojan, true
	case "shadowsocks", "ss":
		return Shadowsocks, true
	case "socks", "socks5":
		return SOCKS5, true
	default:
		return "", false
	}
}

func parseJSONOutbound(ob map[string]any, nameOverride, fullConfigJSON string) (ServerProfile, bool) {
	protocol, ok := normalizeJSONProtocol(firstNonEmpty(stringVal(ob["protocol"]), stringVal(ob["type"])))
	if !ok {
		return ServerProfile{}, false
	}

	settings, _ := ob["settings"].(map[string]any)
	endpoint := firstObjectInSlice(settings, "vnext")
	if endpoint == nil {
		endpoint = firstObjectInSlice(settings, "servers")
	}
	if endpoint == nil {
		endpoint = settings
	}
	if endpoint == nil {
		endpoint = ob
	}

	user := firstObjectInSlice(endpoint, "users")
	if user == nil {
		user = firstObjectInSlice(settings, "servers")
	}
	if user == nil {
		user = endpoint
	}

	address := strings.TrimSpace(firstNonEmpty(stringVal(endpoint["address"]), stringVal(endpoint["server"]), stringVal(ob["server"])))
	if address == "" {
		return ServerProfile{}, false
	}
	port := intVal(endpoint["port"])
	if port == 0 {
		port = intVal(ob["port"])
	}
	if port < 1 || port > 65535 {
		if protocol == SOCKS5 {
			port = 1080
		} else {
			port = 443
		}
	}

	stream, _ := ob["streamSettings"].(map[string]any)
	network := normalizeNetwork(firstNonEmpty(stringVal(stream["network"]), stringVal(ob["network"]), "tcp"))
	security := strings.ToLower(strings.TrimSpace(firstNonEmpty(stringVal(stream["security"]), "none")))

	tlsSettings, _ := stream["tlsSettings"].(map[string]any)
	realitySettings, _ := stream["realitySettings"].(map[string]any)
	sni := firstNonEmpty(stringVal(realitySettings["serverName"]), stringVal(tlsSettings["serverName"]), stringVal(ob["sni"]))
	fp := firstNonEmpty(stringVal(realitySettings["fingerprint"]), stringVal(tlsSettings["fingerprint"]), "chrome")

	name := firstNonEmpty(nameOverride, stringVal(ob["remarks"]), stringVal(ob["name"]), stringVal(ob["tag"]), net.JoinHostPort(address, strconv.Itoa(port)))

	profile := ServerProfile{
		Protocol:       protocol,
		Name:           name,
		Address:        address,
		Port:           port,
		Network:        network,
		Security:       security,
		SNI:            sni,
		Fingerprint:    fp,
		PublicKey:      stringVal(realitySettings["publicKey"]),
		ShortID:        stringVal(realitySettings["shortId"]),
		SpiderX:        stringVal(realitySettings["spiderX"]),
		FullConfigJSON: fullConfigJSON,
	}

	switch protocol {
	case VLESS:
		profile.ID = firstNonEmpty(stringVal(user["id"]), stringVal(ob["uuid"]))
		profile.Flow = stringVal(user["flow"])
		profile.Encryption = firstNonEmpty(stringVal(user["encryption"]), "none")
	case VMess:
		profile.ID = firstNonEmpty(stringVal(user["id"]), stringVal(ob["uuid"]))
		profile.Encryption = firstNonEmpty(stringVal(user["security"]), "auto")
	case Trojan:
		profile.Password = firstNonEmpty(stringVal(endpoint["password"]), stringVal(user["password"]), stringVal(ob["password"]))
	case Shadowsocks:
		profile.Encryption = firstNonEmpty(stringVal(endpoint["method"]), stringVal(ob["cipher"]), "aes-256-gcm")
		profile.Password = firstNonEmpty(stringVal(endpoint["password"]), stringVal(ob["password"]))
	case SOCKS5:
		profile.Username = stringVal(user["user"])
		profile.Password = stringVal(user["pass"])
	}

	return profile, true
}

func sliceOfObjects(raw any) []map[string]any {
	items, ok := raw.([]any)
	if !ok {
		return nil
	}
	result := make([]map[string]any, 0, len(items))
	for _, item := range items {
		if obj, ok := item.(map[string]any); ok {
			result = append(result, obj)
		}
	}
	return result
}

func firstObjectInSlice(container map[string]any, key string) map[string]any {
	if container == nil {
		return nil
	}
	items := sliceOfObjects(container[key])
	if len(items) == 0 {
		return nil
	}
	return items[0]
}

func stringVal(raw any) string {
	switch v := raw.(type) {
	case string:
		return v
	default:
		return ""
	}
}

func intVal(raw any) int {
	switch v := raw.(type) {
	case float64:
		return int(v)
	case int:
		return v
	case string:
		n, _ := strconv.Atoi(strings.TrimSpace(v))
		return n
	default:
		return 0
	}
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if strings.TrimSpace(v) != "" {
			return v
		}
	}
	return ""
}

func shallowCloneMap(src map[string]any) map[string]any {
	dst := make(map[string]any, len(src))
	for k, v := range src {
		dst[k] = v
	}
	return dst
}

func sameMapRef(a, b map[string]any) bool {
	if len(a) != len(b) {
		return false
	}
	// Compare by serialized JSON for deterministic deduplication of candidate outbounds.
	ab, errA := json.Marshal(a)
	bb, errB := json.Marshal(b)
	return errA == nil && errB == nil && string(ab) == string(bb)
}
