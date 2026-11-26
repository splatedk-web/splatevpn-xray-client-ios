package imports

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"net"
	"regexp"
	"strconv"
	"strings"
	"unicode"
	"unicode/utf8"
)

var (
	vlessLink  = regexp.MustCompile(`(?i)vless://[^\s"'<>\p{Z}]+`)
	serverLink = regexp.MustCompile(`(?i)(?:vless|vmess|trojan|ss|socks5?|hy2|hysteria2)://[^\s"'<>\p{Z}]+`)
)

type Protocol string

const (
	VLESS       Protocol = "vless"
	VMess       Protocol = "vmess"
	Trojan      Protocol = "trojan"
	Shadowsocks Protocol = "shadowsocks"
	SOCKS5      Protocol = "socks"
	Hysteria2   Protocol = "hysteria2"
)

type ServerProfile struct {
	Protocol             Protocol
	Name, Description    string
	Address              string
	Port                 int
	Username, Password   string
	ID, Flow, Encryption string
	Network, Security    string
	SNI, Fingerprint     string
	PublicKey, ShortID   string
	SpiderX, Path, Host  string
	Mode, Padding        string
	Obfs, ObfsPassword   string
	PinSHA256            string
	HopPorts             string
	HopInterval          int
	RawLink              string
	FullConfigJSON       string
}

type VLESSProfile = ServerProfile

// ParseVLESSSubscription imports VLESS links from a plain or Base64 subscription.
func ParseVLESSSubscription(raw string) ([]VLESSProfile, error) {
	return parseSubscriptionProfiles(raw, vlessLink)
}

// ParseServerSubscription imports supported server links or JSON profiles in their original order.
func ParseServerSubscription(raw string) ([]ServerProfile, error) {
	body, err := DecodeSubscriptionBody(raw)
	if err != nil {
		return nil, err
	}
	trimmed := strings.TrimSpace(body)
	if strings.HasPrefix(trimmed, "{") || strings.HasPrefix(trimmed, "[") {
		profiles, jsonErr := parseJSONSubscription(trimmed)
		if jsonErr != nil {
			return nil, jsonErr
		}
		if len(profiles) > 0 {
			return profiles, nil
		}
	}
	if strings.Contains(trimmed, "proxies:") {
		profiles, yamlErr := parseClashYAML(trimmed)
		if yamlErr != nil {
			return nil, yamlErr
		}
		if len(profiles) > 0 {
			return profiles, nil
		}
	}
	return parseDecodedProfiles(body, serverLink)
}

func parseSubscriptionProfiles(raw string, pattern *regexp.Regexp) ([]ServerProfile, error) {
	body, err := DecodeSubscriptionBody(raw)
	if err != nil {
		return nil, err
	}
	return parseDecodedProfiles(body, pattern)
}

func parseDecodedProfiles(body string, pattern *regexp.Regexp) ([]ServerProfile, error) {
	const maxProfiles = 20_000
	var profiles []ServerProfile
	for offset := 0; offset < len(body); {
		match := pattern.FindStringIndex(body[offset:])
		if match == nil {
			break
		}
		profile, err := ParseServerLink(body[offset+match[0] : offset+match[1]])
		offset += match[1]
		if err != nil {
			continue
		}
		if len(profiles) == maxProfiles {
			return nil, errors.New("too many subscription profiles")
		}
		profiles = append(profiles, profile)
	}
	return profiles, nil
}

// ParseVLESS preserves literal '+' in credentials and transport options.
func ParseVLESS(raw string) (VLESSProfile, error) {
	if !strings.HasPrefix(strings.ToLower(strings.TrimSpace(raw)), "vless://") {
		return ServerProfile{}, errors.New("invalid VLESS link")
	}
	return ParseServerLink(raw)
}

func ParseServerLink(raw string) (ServerProfile, error) {
	raw = strings.TrimSpace(raw)
	scheme, payload, _ := strings.Cut(raw, "://")
	protocol := Protocol(strings.ToLower(scheme))
	switch protocol {
	case VMess:
		return parseVMess(raw)
	case "ss", Shadowsocks:
		return parseShadowsocks(raw)
	case "hy2", Hysteria2:
		return parseHysteria2(raw)
	case "socks5":
		protocol = SOCKS5
	}
	defaultPort := 443
	switch protocol {
	case VLESS, Trojan:
	case SOCKS5:
		defaultPort = 1080
	default:
		return ServerProfile{}, errors.New("unsupported server protocol")
	}
	link, label, hasLabel := strings.Cut(payload, "#")
	location, rawQuery, _ := strings.Cut(link, "?")
	authority, uriPath, _ := strings.Cut(location, "/")
	var credentials string
	if at := strings.LastIndexByte(authority, '@'); at >= 0 {
		credentials, authority = authority[:at], authority[at+1:]
	}
	if protocol == VLESS && credentials == "" {
		return ServerProfile{}, errors.New("missing VLESS credentials")
	}
	host, port, err := parseEndpoint(authority, defaultPort)
	if err != nil {
		return ServerProfile{}, err
	}
	if protocol == SOCKS5 {
		name := "SOCKS5-" + host + ":" + strconv.Itoa(port)
		if hasLabel {
			name = decodeLabel(label)
		}
		user, password := socksCredentials(credentials)
		return ServerProfile{
			Protocol: protocol, Name: name, Address: host, Port: port, Username: user,
			Password: password, Network: "tcp", Security: "none", RawLink: raw,
		}, nil
	}

	options := make(map[string]string)
	for _, part := range strings.Split(rawQuery, "&") {
		if key, value, found := strings.Cut(part, "="); found && strings.TrimSpace(key) != "" {
			options[strings.TrimSpace(key)] = unescape(value)
		}
	}
	option := func(fallback string, keys ...string) string {
		for _, key := range keys {
			if value, found := options[key]; found {
				return value
			}
		}
		return fallback
	}

	networkKeys := []string{"type", "net", "transport"}
	if protocol == VLESS {
		networkKeys = append(networkKeys, "network")
	}
	network := normalizeNetwork(option("tcp", networkKeys...))
	if protocol == VLESS && network == "xdrive" {
		return ServerProfile{}, errors.New("XDrive requires a JSON profile")
	}
	name := net.JoinHostPort(host, strconv.Itoa(port))
	var description string
	sniDefault := ""
	if protocol == Trojan {
		name = "Trojan-" + host
		sniDefault = host
		if hasLabel {
			name = decodeLabel(label)
		}
	} else if hasLabel {
		name, description = vlessLabel(label)
	}
	publicKey := option("", "pbk", "publicKey")
	defaultSecurity := "none"
	switch {
	case publicKey != "":
		defaultSecurity = "reality"
	case port == 443 || protocol == Trojan:
		defaultSecurity = "tls"
	}

	path := option("", "path", "serviceName")
	if network == "grpc" {
		if path = strings.TrimSpace(path); path == "" {
			path = strings.TrimSpace(uriPath)
		}
	} else {
		if path == "" {
			path = strings.TrimSpace(uriPath)
		}
		if !strings.HasPrefix(path, "/") {
			path = "/" + path
		}
	}

	mode := option("auto", "mode")
	padding := option("100-1000", "x_padding_bytes")
	if extra := option("", "extra"); extra != "" {
		var fields map[string]json.RawMessage
		if json.Unmarshal([]byte(unescape(extra)), &fields) == nil {
			mode = extraString(fields["mode"], mode)
			padding = extraString(fields["xPaddingBytes"], padding)
		}
	}

	profile := ServerProfile{
		Protocol: protocol, Name: name, Description: description, Address: host, Port: port,
		Network: network, Security: strings.ToLower(strings.TrimSpace(option(defaultSecurity, "security", "sec"))),
		SNI: option(sniDefault, "sni", "peer", "serverName"), Fingerprint: option("chrome", "fp", "fingerprint"),
		PublicKey: publicKey, ShortID: option("", "sid", "shortId"), SpiderX: option("", "spx", "spiderX"),
		Path: path, Host: option("", "host", "authority"),
		Mode: mode, Padding: padding, RawLink: raw,
	}
	if protocol == Trojan {
		profile.Password = unescape(credentials)
	} else {
		profile.ID = unescape(credentials)
		profile.Flow = option("", "flow")
		profile.Encryption = option("none", "encryption")
		profile.Host = option("", "host", "authority", "obfsParam")
	}
	return profile, nil
}

func parseEndpoint(authority string, defaultPort int) (string, int, error) {
	invalid := errors.New("invalid server endpoint")
	host := authority
	port := defaultPort
	if strings.HasPrefix(host, "[") && strings.HasSuffix(host, "]") {
		host = strings.TrimSuffix(strings.TrimPrefix(host, "["), "]")
		if net.ParseIP(host) == nil {
			return "", 0, invalid
		}
	} else if strings.Contains(host, ":") {
		var portText string
		var err error
		host, portText, err = net.SplitHostPort(authority)
		if err != nil {
			return "", 0, invalid
		}
		port, err = strconv.Atoi(portText)
		if err != nil || port < 1 || port > 65535 {
			return "", 0, invalid
		}
	}
	host = strings.TrimSpace(host)
	if host == "" || strings.ContainsAny(host, "[]") || strings.IndexFunc(host, unicode.IsSpace) >= 0 {
		return "", 0, invalid
	}
	return host, port, nil
}

func normalizeNetwork(raw string) string {
	switch value := strings.ToLower(strings.TrimSpace(raw)); value {
	case "splithttp", "xhttp":
		return "xhttp"
	case "websocket", "ws":
		return "ws"
	case "h2", "http":
		return "h2"
	case "grpc", "gun":
		return "grpc"
	case "kcp", "mkcp":
		return "kcp"
	case "httpupgrade", "xdrive", "hysteria":
		return value
	default:
		return "tcp"
	}
}

func vlessLabel(raw string) (string, string) {
	const suffix = "?serverDescription="
	label := unescape(raw)
	if i := strings.LastIndex(label, suffix); i > 0 {
		description := decodeBase64(label[i+len(suffix):])
		if isDescription(description) {
			if nested := decodeBase64(description); isDescription(nested) {
				description = nested
			}
			description = strings.TrimSpace(description)
			if len(description) > 4 && strings.HasPrefix(description, "**") && strings.HasSuffix(description, "**") {
				description = strings.TrimSpace(description[2 : len(description)-2])
			}
			if description != "" {
				return strings.TrimRightFunc(label[:i], unicode.IsSpace), description
			}
		}
	}
	return decodeLabel(raw), ""
}

func decodeLabel(raw string) string {
	return unescape(strings.ReplaceAll(raw, "+", " "))
}

func socksCredentials(raw string) (user, password string) {
	if user, password, ok := strings.Cut(raw, ":"); ok {
		return unescape(user), unescape(password)
	}
	if !strings.Contains(raw, "%") {
		decoded := decodeBase64(raw)
		canonical := base64.RawStdEncoding.EncodeToString([]byte(decoded))
		standard := strings.NewReplacer("-", "+", "_", "/").Replace(strings.TrimRight(raw, "="))
		if user, password, ok := strings.Cut(decoded, ":"); ok && canonical == standard &&
			utf8.ValidString(decoded) && strings.IndexFunc(decoded, unicode.IsControl) < 0 {
			return user, password
		}
	}
	return unescape(raw), ""
}

func isDescription(value string) bool {
	value = strings.TrimSpace(value)
	return value != "" && utf8.ValidString(value) && strings.IndexFunc(value, func(r rune) bool {
		return unicode.IsControl(r) || unicode.Is(unicode.Cf, r) || r == utf8.RuneError
	}) < 0
}

func extraString(field json.RawMessage, fallback string) string {
	var value string
	if err := json.Unmarshal(field, &value); err == nil && string(field) != "null" {
		return value
	}
	var number json.Number
	if err := json.Unmarshal(field, &number); err == nil && number != "" {
		return string(number)
	}
	if string(field) == "true" || string(field) == "false" {
		return string(field)
	}
	return fallback
}
