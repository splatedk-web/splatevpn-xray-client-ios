package imports

import (
	"encoding/json"
	"errors"
	"strconv"
	"strings"
)

func parseVMess(raw string) (ServerProfile, error) {
	_, payload, found := strings.Cut(raw, "://")
	if !found {
		return ServerProfile{}, errors.New("invalid VMess link")
	}
	linkPart, fragment, hasFragment := strings.Cut(payload, "#")
	encoded, _, _ := strings.Cut(linkPart, "?")
	decoded := decodeBase64(strings.TrimSpace(encoded))
	if decoded == "" {
		return ServerProfile{}, errors.New("invalid VMess Base64 payload")
	}

	var fields map[string]json.RawMessage
	if err := json.Unmarshal([]byte(decoded), &fields); err != nil {
		return ServerProfile{}, errors.New("invalid VMess JSON payload")
	}

	host := strings.TrimSpace(jsonStringField(fields, "add"))
	if host == "" {
		return ServerProfile{}, errors.New("missing VMess host")
	}
	port, err := jsonPortField(fields, "port", 443)
	if err != nil {
		return ServerProfile{}, err
	}

	name := strings.TrimSpace(jsonStringField(fields, "ps"))
	if name == "" && hasFragment {
		name = strings.TrimSpace(decodeLabel(fragment))
	}
	if name == "" {
		name = "VMess-" + host
	}

	rawNet := jsonStringField(fields, "net")
	if rawNet == "" {
		rawNet = jsonStringField(fields, "type")
	}
	network := normalizeNetwork(rawNet)

	security := "none"
	if isTruthyJSON(fields["tls"], "tls") {
		security = "tls"
	}

	httpHost := jsonStringField(fields, "host")
	sni := strings.TrimSpace(jsonStringField(fields, "sni"))
	if sni == "" {
		firstHost, _, _ := strings.Cut(httpHost, ",")
		sni = strings.TrimSpace(firstHost)
	}
	if sni == "" {
		sni = host
	}

	rawPath := jsonStringField(fields, "path")
	path := rawPath
	if network == "grpc" {
		path = strings.TrimSpace(rawPath)
	} else {
		if path == "" {
			path = "/"
		} else if !strings.HasPrefix(path, "/") {
			path = "/" + path
		}
	}

	encryption := strings.TrimSpace(jsonStringField(fields, "scy"))
	if encryption == "" {
		encryption = "auto"
	}
	fingerprint := strings.TrimSpace(jsonStringField(fields, "fp"))
	if fingerprint == "" {
		fingerprint = "chrome"
	}
	mode := strings.TrimSpace(jsonStringField(fields, "mode"))
	if mode == "" {
		mode = "auto"
	}

	return ServerProfile{
		Protocol:    VMess,
		Name:        name,
		Address:     host,
		Port:        port,
		ID:          jsonStringField(fields, "id"),
		Encryption:  encryption,
		Network:     network,
		Security:    security,
		SNI:         sni,
		Fingerprint: fingerprint,
		Path:        path,
		Host:        httpHost,
		Mode:        mode,
		RawLink:     raw,
	}, nil
}

func parseShadowsocks(raw string) (ServerProfile, error) {
	_, payload, found := strings.Cut(raw, "://")
	if !found {
		return ServerProfile{}, errors.New("invalid Shadowsocks link")
	}
	mainPart, fragment, hasFragment := strings.Cut(payload, "#")
	connectionPart, _, _ := strings.Cut(mainPart, "?")

	var method, password, host string
	port := 8388

	if at := strings.LastIndexByte(connectionPart, '@'); at >= 0 {
		userInfoEncoded := connectionPart[:at]
		hostPort, _, _ := strings.Cut(connectionPart[at+1:], "/")

		var decodedUserInfo string
		switch {
		case strings.Contains(userInfoEncoded, ":"):
			m, p, _ := strings.Cut(userInfoEncoded, ":")
			decodedUserInfo = unescape(m) + ":" + unescape(p)
		case strings.Contains(strings.ToLower(userInfoEncoded), "%3a"):
			decodedUserInfo = unescape(userInfoEncoded)
		default:
			decodedUserInfo = decodeBase64(userInfoEncoded)
		}
		if m, p, ok := strings.Cut(decodedUserInfo, ":"); ok {
			method, password = strings.TrimSpace(m), p
		}
		var err error
		host, port, err = parseEndpoint(hostPort, 8388)
		if err != nil {
			return ServerProfile{}, err
		}
	} else {
		body, _, _ := strings.Cut(connectionPart, "/")
		decoded := decodeBase64(body)
		at := strings.LastIndexByte(decoded, '@')
		if at < 0 {
			return ServerProfile{}, errors.New("invalid legacy Shadowsocks link")
		}
		userInfo := decoded[:at]
		hostPort := decoded[at+1:]
		if m, p, ok := strings.Cut(userInfo, ":"); ok {
			method, password = strings.TrimSpace(m), p
		}
		var err error
		host, port, err = parseEndpoint(hostPort, 8388)
		if err != nil {
			return ServerProfile{}, err
		}
	}

	if host == "" || method == "" {
		return ServerProfile{}, errors.New("missing Shadowsocks host or cipher method")
	}

	name := "Shadowsocks-" + host + ":" + strconv.Itoa(port)
	if hasFragment {
		if decoded := strings.TrimSpace(decodeLabel(fragment)); decoded != "" {
			name = decoded
		}
	}

	return ServerProfile{
		Protocol:   Shadowsocks,
		Name:       name,
		Address:    host,
		Port:       port,
		Password:   password,
		Encryption: method,
		Network:    "tcp",
		Security:   "none",
		RawLink:    raw,
	}, nil
}

func jsonStringField(fields map[string]json.RawMessage, keys ...string) string {
	for _, key := range keys {
		raw, ok := fields[key]
		if !ok || len(raw) == 0 || string(raw) == "null" {
			continue
		}
		var s string
		if json.Unmarshal(raw, &s) == nil {
			return s
		}
		var n json.Number
		if json.Unmarshal(raw, &n) == nil && n != "" {
			return string(n)
		}
	}
	return ""
}

func jsonPortField(fields map[string]json.RawMessage, key string, defaultPort int) (int, error) {
	raw, ok := fields[key]
	if !ok || len(raw) == 0 || string(raw) == "null" {
		return defaultPort, nil
	}
	var num int
	if json.Unmarshal(raw, &num) == nil {
		if num < 1 || num > 65535 {
			return 0, errors.New("invalid port")
		}
		return num, nil
	}
	var text string
	if json.Unmarshal(raw, &text) == nil {
		text = strings.TrimSpace(text)
		if text == "" {
			return defaultPort, nil
		}
		parsed, err := strconv.Atoi(text)
		if err != nil || parsed < 1 || parsed > 65535 {
			return 0, errors.New("invalid port")
		}
		return parsed, nil
	}
	return 0, errors.New("invalid port")
}

func isTruthyJSON(raw json.RawMessage, extraWord string) bool {
	if len(raw) == 0 || string(raw) == "null" {
		return false
	}
	var b bool
	if json.Unmarshal(raw, &b) == nil {
		return b
	}
	var s string
	if json.Unmarshal(raw, &s) == nil {
		lower := strings.ToLower(strings.TrimSpace(s))
		return lower == "true" || lower == "1" || (extraWord != "" && lower == extraWord)
	}
	var n int
	if json.Unmarshal(raw, &n) == nil {
		return n == 1
	}
	return false
}
